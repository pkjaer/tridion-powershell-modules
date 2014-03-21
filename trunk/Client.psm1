#Requires -version 2.0

$ErrorActionPreference = "Stop";

<#
**************************************************
* Private members
**************************************************
#>

Function Get-CoreServiceBinding
{
	$settings = Get-TridionCoreServiceSettings
	$type = $settings.ConnectionType;
	
	$quotas = New-Object System.Xml.XmlDictionaryReaderQuotas;
	$quotas.MaxStringContentLength = 10485760;
	$quotas.MaxArrayLength = 10485760;
	$quotas.MaxBytesPerRead = 10485760;

	switch($type)
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
    Make sure you call the Close method when you are done with the client (i.e. in a finally block).

    .Inputs
    None.

    .Outputs
    Returns a client of type [Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient].

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

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
            if ($client -ne $null) { $client.Close() | Out-Null; }
        }
    }

    #>
    [CmdletBinding()]
    Param()

    Begin
    {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.ServiceModel

        # Load information about the Core Service client available on this system
        $serviceInfo = Get-TridionCoreServiceSettings
        
        Write-Verbose ("Connecting to the Core Service at {0}..." -f $serviceInfo.HostName);
        
        # Load the Core Service Client
        $endpoint = New-Object System.ServiceModel.EndpointAddress -ArgumentList $serviceInfo.EndpointUrl
        $binding = Get-CoreServiceBinding;
        [Reflection.Assembly]::LoadFrom($serviceInfo.AssemblyPath) | Out-Null;            
    }
    
    Process
    {
        try
        {
            $proxy = New-Object $serviceInfo.ClassName -ArgumentList $binding, $endpoint;

            Write-Verbose ("Connecting as {0}" -f $serviceInfo.UserName);
            $proxy.Impersonate($serviceInfo.UserName) | Out-Null;
            
            return $proxy;
        }
        catch [System.Exception]
        {
            Write-Error $_;
            return $null;
        }
    }
}


<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-TridionCoreServiceClient