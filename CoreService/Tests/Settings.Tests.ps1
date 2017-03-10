$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

<#
**************************************************
* Helper functions
**************************************************
#>
Function GetTestCredential
{
	$plainPassword = "P@ssw0rd"
	$securePassword = $plainPassword | ConvertTo-SecureString -AsPlainText -Force
	$userName = "Domain\User"
	return New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
}

Function VerifyDefaultSettings($settings, $excludingProperties = @())
{
	if ($excludingProperties -notcontains "AssemblyPath") { $settings.AssemblyPath | Should Be (Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll'); };
	if ($excludingProperties -notcontains "ClassName") { $settings.ClassName | Should Be 'Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient'; }
	if ($excludingProperties -notcontains "EndpointUrl") { $settings.EndpointUrl | Should Be "http://localhost/webservices/CoreService2011.svc/wsHttp"; }
	if ($excludingProperties -notcontains "ConnectionSendTimeout") { $settings.ConnectionSendTimeout | Should Be "00:01:00"; }
	if ($excludingProperties -notcontains "HostName") { $settings.HostName | Should Be "localhost"; }
	if ($excludingProperties -notcontains "Credential") { $settings.Credential | Should Be $null; }
	if ($excludingProperties -notcontains "Version") { $settings.Version | Should Be "2011-SP1"; }
	if ($excludingProperties -notcontains "ConnectionType") { $settings.ConnectionType | Should Be "Default"; }
	if ($excludingProperties -notcontains "ModuleVersion") { $settings.ModuleVersion | Should Be $moduleVersion; }
}

Function SetToNonDefaultSettingsAndVerify
{
	$returnValue = Set-TridionCoreServiceSettings -HostName "invalid" -Version '2013-SP1' -ConnectionType netTcp -ConnectionSendTimeout 00:00:55 -Credential (GetTestCredential) -PassThru;
	$stored = Get-TridionCoreServiceSettings;
	
	# Validate that both the return value from the method and the object returned by Get-TridionCoreServiceSettings have the expected values
	foreach ($settingsObject in @($returnValue, $stored))
	{
		$settingsObject.AssemblyPath | Should Be (Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013sp1.dll');
		$settingsObject.ClassName | Should Be "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
		$settingsObject.EndpointUrl | Should Be "net.tcp://invalid:2660/CoreService/2013/netTcp";
		$settingsObject.ConnectionSendTimeout | Should Be "00:00:55";
		$settingsObject.HostName | Should Be "invalid";
		$settingsObject.Credential | Should Not Be $null;
		$settingsObject.Version | Should Be "2013-SP1";
		$settingsObject.ConnectionType | Should Be "netTcp";
		$settingsObject.ModuleVersion | Should Be $moduleVersion;
	}
}


<#
**************************************************
* Tests
**************************************************
#>

Describe "Core Service Settings Tests" {
	BeforeAll {
		$parent = Split-Path -Parent $here
		$clientDir = Join-Path $parent 'Clients';
		
		Get-Module Tridion-CoreService | Remove-Module
		Import-Module (Join-Path $parent "Tridion-CoreService.psd1") -Force;
		$moduleVersion = (Get-Module Tridion-CoreService).Version;

		# Get default settings for later comparison
		$defaultSettings = Clear-TridionCoreServiceSettings;
	}
	
	Context "Clear-TridionCoreServiceSettings" {
		It "returns the updated settings" {
			$result = Clear-TridionCoreServiceSettings -PassThru;
			$result | Should Not BeNullOrEmpty;
			VerifyDefaultSettings $result;
		}
	 
		It "resets all settings to the default values" {
			SetToNonDefaultSettingsAndVerify;
			Clear-TridionCoreServiceSettings;
			VerifyDefaultSettings (Get-TridionCoreServiceSettings);
		}
	}

	Context "Set-TridionCoreServiceSettings" {
		BeforeEach {
			# Resetting the settings before each test.
			Clear-TridionCoreServiceSettings;
		}
	
		It "returns the updated settings" {
			$result = Set-TridionCoreServiceSettings -Version '2011-SP1' -PassThru;
			$result | Should Not BeNullOrEmpty;
			$result.Version | Should Be '2011-SP1';
		}
		
		It "validates input parameter HostName" {
			{ Set-TridionCoreServiceSettings -HostName $null } | Should Throw;
			{ Set-TridionCoreServiceSettings -HostName '' } | Should Throw;
		}

		It "validates input parameter ConnectionType" {
			{ Set-TridionCoreServiceSettings -ConnectionType 'FakeConnectionType' } | Should Throw;
			{ Set-TridionCoreServiceSettings -ConnectionSendTimeout 'FakeConnectionSendTimeout' } | Should Throw;

			$validConnectionTypes = @('', 'Default', 'SSL', 'LDAP', 'LDAP-SSL', 'netTcp');
			foreach ($connectionType in $validConnectionTypes)
			{
				(Set-TridionCoreServiceSettings -ConnectionType $connectionType -PassThru).ConnectionType | Should Be $connectionType;
			}
		}
		
		It "validates input parameter Version" {
			# Test invalid input
			{ Set-TridionCoreServiceSettings -Version 'FakeVersion' } | Should Throw;
			
			# Test the set parameters
			$validVersions = @('', '2011-SP1', '2013', '2013-SP1', 'Web-8.1', 'Web-8.5');
			foreach ($version in $validVersions)
			{
				(Set-TridionCoreServiceSettings -Version $version -PassThru).Version | Should Be $version;
			}
		}
		
		It "updates all settings at once" {
			Clear-TridionCoreServiceSettings;
			VerifyDefaultSettings (Get-TridionCoreServiceSettings);
			SetToNonDefaultSettingsAndVerify;
		}
		
		It "updates HostName only" {
			# Change the hostname only
			$settings = Set-TridionCoreServiceSettings -HostName 'example.org' -PassThru;
			
			# Verify that only the relevant settings have changed
			VerifyDefaultSettings -settings $settings -excludingProperties @('HostName', 'EndpointUrl');
			$settings.HostName | Should Be 'example.org';
			$settings.EndpointUrl | Should Be 'http://example.org/webservices/CoreService2011.svc/wsHttp';
		}
		
		It "handles HostName with a port in it" {
			# Test host names with port in them
			$settings = Set-TridionCoreServiceSettings -HostName 'example.org:81' -PassThru;

			VerifyDefaultSettings -settings $settings -excludingProperties @('HostName', 'EndpointUrl');
			$settings.HostName | Should Be 'example.org:81';
			$settings.EndpointUrl | Should Be 'http://example.org:81/webservices/CoreService2011.svc/wsHttp';
		}
		
		It "handles HostName with a port in it when using netTcp" {
			# Test what happens when the protocol requires a specific port (i.e. netTcp)
			$settings = Set-TridionCoreServiceSettings -HostName 'example.org:81' -ConnectionType netTcp -PassThru;

			VerifyDefaultSettings -settings $settings -excludingProperties @('HostName', 'EndpointUrl', 'ConnectionType');
			$settings.HostName | Should Be 'example.org:81';
			$settings.EndpointUrl | Should Be 'net.tcp://example.org:2660/CoreService/2011/netTcp';
			$settings.ConnectionType | Should Be 'netTcp';
		}

		It "updates ConnectionType only" {
			# Change the ConnectionType only
			$settings = Set-TridionCoreServiceSettings -ConnectionType 'netTcp' -PassThru;
			
			# Verify that only the relevant settings have changed
			VerifyDefaultSettings -settings $settings -excludingProperties @('ConnectionType', 'EndpointUrl');
			$settings.ConnectionType | Should Be 'netTcp';
			$settings.EndpointUrl | Should Be 'net.tcp://localhost:2660/CoreService/2011/netTcp';
		}

		It "updates ConnectionSendTimeout only" {
			# Change the ConnectionSendTimeout only
			$settings = Set-TridionCoreServiceSettings -ConnectionSendTimeout '00:02:00' -PassThru;
			
			# Verify that only the relevant settings have changed
			VerifyDefaultSettings -settings $settings -excludingProperties @('ConnectionSendTimeout');
			$settings.ConnectionSendTimeout | Should Be '00:02:00';
		}

		It "updates Credential only" {
			$testCredential = GetTestCredential;
			
			# Change the Credential only
			$settings = Set-TridionCoreServiceSettings -Credential $testCredential -PassThru;
			
			# Verify that only the relevant settings have changed
			VerifyDefaultSettings -settings $settings -excludingProperties @('Credential');
			$settings.Credential | Should Be $testCredential;
		}

		It "updates Version only" {
			# Change the Credential only
			$settings = Set-TridionCoreServiceSettings -Version 'Web-8.1' -PassThru;
			
			# Verify that only the relevant settings have changed
			VerifyDefaultSettings -settings $settings -excludingProperties @('Version', 'EndpointUrl', 'AssemblyPath');
			$settings.Version | Should Be 'Web-8.1';
			$settings.EndpointUrl | Should Be 'http://localhost/webservices/CoreService201501.svc/wsHttp';
			$settings.AssemblyPath | Should Be (Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_1.dll');
		}
		
		It "updates EndpointUrl automatically" {
			# Test URLs hosted in IIS first
			$relativeUrls = @{
				'2011-SP1' = 'localhost/webservices/CoreService2011.svc/wsHttp';
				'2013' = 'localhost/webservices/CoreService2012.svc/wsHttp';
				'2013-SP1' = 'localhost/webservices/CoreService2013.svc/wsHttp';
				'Web-8.1' = 'localhost/webservices/CoreService201501.svc/wsHttp';
				'Web-8.5' = 'localhost/webservices/CoreService201603.svc/wsHttp';
			}
				
			foreach ($entry in $relativeUrls.GetEnumerator())
			{
				$version= $entry.Name;
				$relativeUrl = $entry.Value;
				
				(Set-TridionCoreServiceSettings -Version $version -ConnectionType 'Default' -PassThru).EndpointUrl | Should Be "http://$relativeUrl";
				(Set-TridionCoreServiceSettings -Version $version -ConnectionType 'LDAP' -PassThru).EndpointUrl | Should Be "http://$relativeUrl";
				(Set-TridionCoreServiceSettings -Version $version -ConnectionType 'SSL' -PassThru).EndpointUrl | Should Be "https://$relativeUrl";
				(Set-TridionCoreServiceSettings -Version $version -ConnectionType 'LDAP-SSL' -PassThru).EndpointUrl | Should Be "https://$relativeUrl";
			}
				
			# Test URLs hosted by the Service Host (netTcp)
			$relativeUrls = @{
				'2011-SP1' = 'localhost:2660/CoreService/2011/netTcp';
				'2013' = 'localhost:2660/CoreService/2012/netTcp';
				'2013-SP1' = 'localhost:2660/CoreService/2013/netTcp';
				'Web-8.1' = 'localhost:2660/CoreService/201501/netTcp';
				'Web-8.5' = 'localhost:2660/CoreService/201603/netTcp';
				}
				
			foreach ($entry in $relativeUrls.GetEnumerator())
			{
				$version= $entry.Name;
				$relativeUrl = $entry.Value;
				
				(Set-TridionCoreServiceSettings -Version $version -ConnectionType 'netTcp' -PassThru).EndpointUrl | Should Be "net.tcp://$relativeUrl";
			}
		}
	}	
}