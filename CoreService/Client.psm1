#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

Function Get-CoreServiceBinding
{
	$settings = Get-TridionCoreServiceSettings

	$quotas = New-Object System.Xml.XmlDictionaryReaderQuotas;
	$quotas.MaxStringContentLength = 10485760;
	$quotas.MaxArrayLength = 10485760;
	$quotas.MaxBytesPerRead = 10485760;

	switch($settings.ConnectionType)
	{
		"LDAP" 
		{ 
			$binding = New-Object System.ServiceModel.WSHttpBinding;
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Message;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Basic");
		}
		"LDAP-SSL"
		{
			$binding = New-Object System.ServiceModel.WSHttpBinding;
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Transport;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Basic")
		}
		"netTcp" 
		{ 
			$binding = New-Object System.ServiceModel.NetTcpBinding; 
			$binding.transactionFlow = $true;
			$binding.transactionProtocol = [ServiceModel.TransactionProtocol]::OleTransactions;
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Transport;
			$binding.Security.Transport.ClientCredentialType = "Windows";
		}
		"SSL"
		{
			$binding = New-Object System.ServiceModel.WSHttpBinding;
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Transport;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Windows")
		}
		"BASIC"
		{
			$binding = New-Object System.ServiceModel.BasicHttpBinding;
			$binding.Security.Mode = [System.ServiceModel.BasicHttpSecurityMode]::TransportCredentialOnly;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Windows")
		}
		"BASIC-SSL"
		{
			$binding = New-Object System.ServiceModel.BasicHttpsBinding;
			$binding.Security.Mode = [System.ServiceModel.BasicHttpsSecurityMode]::Transport;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Windows")
		}
		default 
		{ 
			$binding = New-Object System.ServiceModel.WSHttpBinding; 
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Message;
			$binding.Security.Transport.ClientCredentialType = (Get-ClientCredentialType -DefaultValue "Windows")
		}
	}
	
	$binding.SendTimeout = $settings.ConnectionSendTimeout;
	$binding.MaxReceivedMessageSize = [int]::MaxValue;
	$binding.ReaderQuotas = $quotas;
	return $binding;
}

Function Get-ClientCredentialType
{
	[CmdletBinding()]
	Param(
		[string]$DefaultValue
	)
	Process{
		$settings = Get-TridionCoreServiceSettings
		if ($settings.CredentialType -eq 'Default')
		{
			return $DefaultValue
		}
	  else
		{
			return $settings.CredentialType
		}
  }
}
<#
**************************************************
* Public members
**************************************************
#>
Function Get-TridionCoreServiceClient
{
    <#
    .Synopsis
    Gets a client capable of accessing the Tridion Core Service.

    .Description
    Gets a session-aware Core Service client. The Core Service version, binding, and host machine can be modified using Set-TridionCoreServiceSettings.

    .Notes
    Make sure you call Close-TridionCoreServiceClient when you are done with the client (i.e. in a finally block).

    .Inputs
    None.

    .Outputs
    Returns a client of type [Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    $client = Get-TridionCoreServiceClient;
    if ($client -ne $null)
    {
        try
        {
            $client.GetCurrentUser();
        }
        finally
        {
			Close-TridionCoreServiceClient $client;
        }
    }

    #>
    [CmdletBinding()]
    Param(
		# The name (including domain) of the user to impersonate when accessing Tridion. 
		# When omitted the current user will be executing all Tridion commands.
        [Parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ImpersonateUserName
	)

    Begin
    {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.ServiceModel

        # Load information about the Core Service client available on this system
        $serviceInfo = Get-TridionCoreServiceSettings
        
        Write-Verbose ("Connecting to the Core Service at {0}..." -f $serviceInfo.EndpointUrl);
        
        # Load the Core Service Client
        $endpoint = New-Object System.ServiceModel.EndpointAddress -ArgumentList $serviceInfo.EndpointUrl
        $binding = Get-CoreServiceBinding;

        #Load the assembly without locking the file
        Write-Verbose ("Loading assembly {0}" -f $serviceInfo.AssemblyPath) 
		$assemblyBytes = [IO.File]::ReadAllBytes($serviceInfo.AssemblyPath);
		if (!$assemblyBytes) { throw "Unable to load the assembly at: " + $serviceInfo.AssemblyPath; }
        $assembly = [Reflection.Assembly]::Load($assemblyBytes);
		$instanceType = $assembly.GetType($serviceInfo.ClassName, $true, $true);
    }
    
    Process
    {
        try
        {
			$proxy = [Activator]::CreateInstance($instanceType.FullName, $binding, $endpoint);
			if ($serviceInfo.Credential)
			{
				$userName = $serviceInfo.Credential.UserName;
				Write-Verbose "Connecting as $userName..."
				$proxy.ClientCredentials.Windows.ClientCredential = [System.Net.NetworkCredential]$serviceInfo.Credential;

        if ($binding.Security.Transport.ClientCredentialType -eq "Basic")
        {
					if ($proxy.ClientCredentials.Windows.ClientCredential.Domain)
					{
						$fullUsername = "{0}\{1}" -f $proxy.ClientCredentials.Windows.ClientCredential.Domain, $proxy.ClientCredentials.Windows.ClientCredential.Username
					}
					else
					{
						$fullUsername = $proxy.ClientCredentials.Windows.ClientCredential.Username
					}
					$proxy.ClientCredentials.UserName.UserName = $fullUsername;
					$proxy.ClientCredentials.UserName.Password = $proxy.ClientCredentials.Windows.ClientCredential.Password;
				}
			}

			if ($ImpersonateUserName)
			{
				Write-Verbose "Impersonating '$ImpersonateUserName'...";
				$proxy.Impersonate($ImpersonateUserName) | Out-Null;
			}
			
            return $proxy;
        }
        catch [System.Exception]
        {
            Write-Error $_;
            return $null;
        }
    }
}

Function Close-TridionCoreServiceClient
{
    <#
    .Synopsis
    Closes the Core Service connection.

    .Description
    This will close the connection, even if it is in a faulted state due to previous exceptions.

    .Notes
    You should call this method in your 'finally' clause or 'End' step.

    .Inputs
    The Core Service client to close.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    $client = Get-TridionCoreServiceClient;
	try
	{
		$client.GetCurrentUser();
	}
	finally
	{
		Close-TridionCoreServiceClient $client;
	}

    #>
    [CmdletBinding()]
    Param(
		# The client to close. It is allowed to be null.
        [Parameter(ValueFromPipeline=$true)]
		$client
	)

	Process
	{
		if ($client -ne $null) 
		{
			if ($client.State -eq 'Faulted')
			{
				$client.Abort() | Out-Null;
			}
			else
			{
				$client.Close() | Out-Null; 
			}
		}
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-TridionCoreServiceClient
Export-ModuleMember Close-TridionCoreServiceClient
