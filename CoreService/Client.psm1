#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

Function Get-CoreServiceBinding
{
	$settings = Get-CoreServiceSettings

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
			$binding.Security.Transport.ClientCredentialType = "Basic";
		}
		"LDAP-SSL"
		{
			$binding = New-Object System.ServiceModel.WSHttpBinding;
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Transport;
			$binding.Security.Transport.ClientCredentialType = "Basic";
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
			$binding.Security.Transport.ClientCredentialType = "Windows";
		}
		default 
		{ 
			$binding = New-Object System.ServiceModel.WSHttpBinding; 
			$binding.Security.Mode = [System.ServiceModel.SecurityMode]::Message;
			$binding.Security.Transport.ClientCredentialType = "Windows";
		}
	}
	
	$binding.MaxReceivedMessageSize = 10485760;
	$binding.ReaderQuotas = $quotas;
	return $binding;
}

Function Get-LoadedCoreServiceClientVersion
{
        $versionSignatures = @{
                        "Tridion.ContentManager.CoreService.Client, Version=6.1.0.996, Culture=neutral, PublicKeyToken=ddfc895746e5ee6b"="2011-SP1"
                        "Tridion.ContentManager.CoreService.Client, Version=7.0.0.2013, Culture=neutral, PublicKeyToken=ddfc895746e5ee6b"="2013"
						"Tridion.ContentManager.CoreService.Client, Version=7.1.0.1245, Culture=neutral, PublicKeyToken=ddfc895746e5ee6b"="2013-SP1-PRE"
                        "Tridion.ContentManager.CoreService.Client, Version=7.1.0.1290, Culture=neutral, PublicKeyToken=ddfc895746e5ee6b"="2013-SP1"
						"Tridion.ContentManager.CoreService.Client, Version=8.1.0.1287, Culture=neutral, PublicKeyToken=ddfc895746e5ee6b"="Web-8.1"
                        }

        foreach ($assembly in [appdomain]::CurrentDomain.GetAssemblies()) 
		{
            if ($versionSignatures.ContainsKey($assembly.FullName))
			{
                return $versionSignatures[$assembly.FullName]
            }
        }
		
		return $null;
}


<#
**************************************************
* Public members
**************************************************
#>
Function Get-CoreServiceClient
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
        [Parameter(ValueFromPipeline=$true)]
		[string]$ImpersonateUserName
	)

    Begin
    {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.ServiceModel

        # Load information about the Core Service client available on this system
        $serviceInfo = Get-CoreServiceSettings
        
		$loadedClientVersion = Get-LoadedCoreServiceClientVersion
        if ($loadedClientVersion -ne $null -and $loadedClientVersion -ne $serviceInfo.Version) 
        {
			$newVersion = $serviceInfo.Version
            throw "You can only load one version of the Core Service client at a time. You have previously loaded the $loadedClientVersion version in this PowerShell session. Create a new session to start using the $newVersion version.";
        }
	
        Write-Verbose ("Connecting to the Core Service at {0}..." -f $serviceInfo.HostName);
        
        # Load the Core Service Client
        $endpoint = New-Object System.ServiceModel.EndpointAddress -ArgumentList $serviceInfo.EndpointUrl
        $binding = Get-CoreServiceBinding;
		
		#Load the assembly without locking the file
		$assemblyBytes = [IO.File]::ReadAllBytes($serviceInfo.AssemblyPath);
		if (!$assemblyBytes) { throw "Unable to load the assembly at: " + $serviceInfo.AssemblyPath; }
        [Reflection.Assembly]::Load($assemblyBytes) | Out-Null;            
    }
    
    Process
    {
        try
        {
			$proxy = New-Object $serviceInfo.ClassName -ArgumentList $binding, $endpoint;

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

Function Close-CoreServiceClient
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
Export-ModuleMember Get-CoreServiceClient
Export-ModuleMember Close-CoreServiceClient