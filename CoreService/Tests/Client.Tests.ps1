$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

<#
**************************************************
* Helper functions
**************************************************
#>

<#
**************************************************
* Tests
**************************************************
#>

Describe "Core Service Client Tests" {
	BeforeAll {
		$parent = Split-Path -Parent $here
		
		Get-Module Tridion-CoreService | Remove-Module
		$modulesToImport = @('Tridion-CoreService.psd1', 'Client.psm1');
		$modulesToImport | ForEach-Object { Import-Module (Join-Path $parent $_) -Force; }
	}

	Context "Get-TridionCoreServiceClient" {
		InModuleScope Client {
			# ***********************
			# Mocks
			# ***********************
			Mock _SetCredential {}
			Mock _SetImpersonateUser {}
			Mock _NewAssemblyInstance {
				return [PSCustomObject]@{};
			}
			
			# ***********************
			# Tests
			# ***********************
			It "does not impersonate and connects as the current user by default" {
				$client = Get-TridionCoreServiceClient;
				Assert-MockCalled _NewAssemblyInstance -Times 1 -Scope It;
				Assert-MockCalled _SetImpersonateUser -Times 0 -Scope It;
				Assert-MockCalled _SetCredential -Times 0 -Scope It;
			}
			
			It "supports impersonation" {
				$client = Get-TridionCoreServiceClient -ImpersonateUserName 'TEST\User01';
				Assert-MockCalled _NewAssemblyInstance -Times 1 -Scope It;
				Assert-MockCalled _SetImpersonateUser -Times 1 -Scope It;
				Assert-MockCalled _SetCredential -Times 0 -Scope It;
			}
			
			It "supports connecting as a different user" {
				$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Domain\User", ("P@ssw0rd" | ConvertTo-SecureString -AsPlainText -Force);			
				Set-TridionCoreServiceSettings -Credential $credential;
				
				$client = Get-TridionCoreServiceClient;
				Assert-MockCalled _NewAssemblyInstance -Times 1 -Scope It;
				Assert-MockCalled _SetCredential -Times 1 -Scope It;
				Assert-MockCalled _SetImpersonateUser -Times 0 -Scope It;
			}
		}
	}	
	
	Context "_GetCoreServiceBinding" {
		It "sets timeout values and length restrictions" {
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$quotas = $binding.ReaderQuotas;
			
			$quotas.MaxStringContentLength | Should Be ([int]::MaxValue);
			$quotas.MaxArrayLength | Should Be ([int]::MaxValue);
			$quotas.MaxBytesPerRead | Should Be ([int]::MaxValue);
			$binding.MaxReceivedMessageSize | Should Be ([int]::MaxValue);
		}
		
		It "sets the configured SendTimeout" {
			Set-TridionCoreServiceSettings -ConnectionSendTimeout '01:02:03';

			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			
			$binding.SendTimeout | Should Be '01:02:03';
		}
		
		It "supports LDAP" {
			Set-TridionCoreServiceSettings -ConnectionType 'LDAP';
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$binding -is [System.ServiceModel.WSHttpBinding] | Should Be $true;
			$binding.Security.Mode | Should Be 'Message';
			$binding.Security.Transport.ClientCredentialType | Should Be 'Basic';
		}

		It "supports LDAP-SSL" {
			Set-TridionCoreServiceSettings -ConnectionType 'LDAP-SSL';
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$binding -is [System.ServiceModel.WSHttpBinding] | Should Be $true;
			$binding.Security.Mode | Should Be 'Transport';
			$binding.Security.Transport.ClientCredentialType | Should Be 'Basic';
		}

		It "supports netTcp" {
			Set-TridionCoreServiceSettings -ConnectionType 'netTcp';
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$binding -is [System.ServiceModel.NetTcpBinding] | Should Be $true;
			$binding.Security.Mode | Should Be 'Transport';
			$binding.transactionFlow | Should Be $true;
			$binding.transactionProtocol.GetType().Name | Should Be 'OleTransactionsProtocol';
			$binding.Security.Transport.ClientCredentialType | Should Be 'Windows';
		}

		It "supports SSL" {
			Set-TridionCoreServiceSettings -ConnectionType 'SSL';
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$binding -is [System.ServiceModel.WSHttpBinding] | Should Be $true;
			$binding.Security.Mode | Should Be 'Transport';
			$binding.Security.Transport.ClientCredentialType | Should Be 'Windows';
		}

		It "uses wsBinding by default" {
			Set-TridionCoreServiceSettings -ConnectionType 'Default';
			$client = Get-TridionCoreServiceClient;
			$binding = $client.ChannelFactory.Endpoint.Binding;
			$binding -is [System.ServiceModel.WSHttpBinding] | Should Be $true;
			$binding.Security.Mode | Should Be 'Message';
			$binding.Security.Transport.ClientCredentialType | Should Be 'Windows';
		}
	}
}