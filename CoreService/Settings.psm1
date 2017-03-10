#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

. (Join-Path $PSScriptRoot 'Utilities.ps1')

Function _Add-SettingIfMissing($Object, $Name, $Value)
{
	if (!(_Has-Property -Object $Object -Name $Name))
	{
		_Add-Property $Object $Name $Value;
		Write-Host -ForegroundColor Green "There is a new setting available: $Name. The default value of '$Value' has been applied."
	}
}

Function _Remove-SettingIfPresent($Object, $Name)
{
	if (_Has-Property -Object $Object -Name $Name)
	{
		$Object.PSObject.Properties.Remove($Name);
		Write-Warning "The setting '$name' is no longer used and has been removed.";
	}
}

Function _Get-DefaultSettings
{
	$clientDir = Join-Path $PSScriptRoot 'Clients';
	$moduleVersion = _Get-ModuleVersion;
	return _New-ObjectWithProperties @{
		"AssemblyPath" = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll';
		"ClassName" = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
		"EndpointUrl" = "http://localhost/webservices/CoreService2011.svc/wsHttp";
		"ConnectionSendTimeout" = "00:01:00";
		"HostName" = "localhost";
		"Credential" = ([PSCredential]$null);
		"Version" = "2011-SP1";
		"ConnectionType" = "Default";
		"ModuleVersion" = $moduleVersion;
		"CredentialType" = "Default";
	};
}

Function _Get-Settings
{
	if ($script:Settings -eq $null)
	{
		$script:Settings = _Restore-Settings;
	}
	
	return $script:Settings;
}

Function _Get-ModuleVersion
{
	return (Get-Module Tridion-CoreService).Version;
}

Function _Convert-OldSettings($settings)
{
	$moduleVersion = _Get-ModuleVersion
	$savedVersion = $settings.ModuleVersion;
	
	$upgradeNeeded = (
		$savedVersion.Major -lt $moduleVersion.Major -or `
		$savedVersion.Minor -lt $moduleVersion.Minor -or `
		$savedVersion.Build -lt $moduleVersion.Build -or `
		$savedVersion.Revision -lt $moduleVersion.Revision
	);
	
	if ($upgradeNeeded)
	{
		Write-Verbose "Upgrading your settings..."
		Add-SettingIfMissing -Object $settings -Name 'ConnectionSendTimeout' -Value '00:01:00';
		Add-SettingIfMissing -Object $settings -Name 'Credential' -Value ([PSCredential]$null);
		Add-SettingIfMissing -Object $settings -Name 'CredentialType' -Value 'Default';
		Remove-SettingIfPresent -Object $settings -Name 'UserName';
		$settings.ModuleVersion = $moduleVersion;
		_Persist-Settings $settings;
	}
	return $settings;
}

Function _Restore-Settings
{
	$settingsDir = Join-Path $PSScriptRoot 'Settings'
	$settingsFile = Join-Path $settingsDir 'CoreServiceSettings.xml';
	
	if (Test-Path $settingsFile)
	{
		try
		{
			return _Convert-OldSettings (Import-Clixml $settingsFile);
		}
		catch
		{
			Write-Warning "Failed to load your existing settings. Using the default settings. "; 
		}
	}
	return _Get-DefaultSettings;
}

Function _Persist-Settings($settings)
{
	if ($settings -ne $null)
	{
		$settingsDir = Join-Path $PSScriptRoot 'Settings'
		$settingsFile = Join-Path $settingsDir 'CoreServiceSettings.xml';
		
		try
		{
			if (!(Test-Path $settingsDir))
			{
				New-Item -Path $settingsDir -ItemType Container | Out-Null
			}
			
			Export-Clixml -Path $settingsFile -InputObject $settings -Confirm:$false -Force;
			$script:Settings = $settings;
		}
		catch
		{
			Write-Error "Failed to save your settings for next time. Perhaps you don't have permissions to modify '$settingsFile'?";
		}
	}
}

Function _Get-HostWithoutPort($host)
{
	$indexOfPort = $host.LastIndexOf(":");
	if ($indexOfPort -gt 0)
	{
		return $host.Substring(0, $indexOfPort);
	}
	return $host;
}

Function _Validate-TimeoutSetting($value)
{
	$parsed = New-Object TimeSpan;

	if (![TimeSpan]::TryParse($value, [ref]$parsed))
	{
		throw "$value is not a valid timeout setting. It should be in the format of hh:mm:ss (e.g. 00:01:20 for one minute and 20 seconds)"
	}
	
	return $value;
}

<#
**************************************************
* Public members
**************************************************
#>

Function Get-TridionCoreServiceSettings
{
    <#
    .Synopsis
    Gets the settings used to connect to the Core Service.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	#>
    [CmdletBinding()]
    Param()
	
	Process { return _Get-Settings; }
}

Function Set-TridionCoreServiceSettings
{
    <#
    .Synopsis
    Changes the settings used to connect to the Core Service.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
5
    .Example
    Set-TridionCoreServiceSettings -HostName "machine.domain" -Version "2013-SP1" -ConnectionType netTcp
	Makes the module connect to a Core Service hosted on "machine.domain", using netTcp bindings and the 2013 SP1 version of the service.
	
    .Example
    Set-TridionCoreServiceSettings -Credential (Get-Credential)
	Prompts for a username and password to use when connecting to Tridion.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
		[ValidateNotNullOrEmpty()]
        [string]$HostName,
		
		[ValidateSet('', '2011-SP1', '2013', '2013-SP1', 'Web-8.1', 'Web-8.5')]
		[string]$Version,
		
		[Parameter()]
		[PSCredential]$Credential,
		
		[ValidateSet('', 'Default', 'Windows', 'Basic')]
		[Parameter()]
		[string]$CredentialType,

		[ValidateSet('', 'Default', 'SSL', 'LDAP', 'LDAP-SSL', 'netTcp', 'Basic', 'Basic-SSL')]
		[Parameter()]
		[string]$ConnectionType,
		
		[Parameter()]
		[string]$ConnectionSendTimeout,
		
		[Parameter()]
		[switch]$Persist,
		
		[Parameter()]
		[switch]$PassThru
    )

    Process
    {
		$parametersSpecified = $MyInvocation.BoundParameters.Keys;
	
		$connectionTypeSpecified = ($parametersSpecified -contains 'ConnectionType');
		$connectionSendTimeoutSpecified = ($parametersSpecified -contains 'ConnectionSendTimeout');
		$credentialSpecified = ($parametersSpecified -contains 'Credential');
		$hostNameSpecified = ($parametersSpecified -contains 'HostName');
		$versionSpecified = ($parametersSpecified -contains 'Version');
		$credentialTypeSpecified = ($parametersSpecified -contains 'CredentialType');
		
		$result = _Get-Settings;
		if ($connectionTypeSpecified) { $result.ConnectionType = $ConnectionType; }
		if ($connectionSendTimeoutSpecified) { $result.ConnectionSendTimeout = _Validate-TimeoutSetting $ConnectionSendTimeout; }
		if ($credentialSpecified) { $result.Credential = $Credential; }
		if ($hostNameSpecified) { $result.HostName = $HostName; }
		if ($versionSpecified) { $result.Version = $Version; }
		if ($credentialTypeSpecified)  {  $result.CredentialType = $CredentialType;  }

		if ($versionSpecified -or $hostNameSpecified -or $connectionTypeSpecified)
		{
			$netTcp =  ($result.connectionType -eq "netTcp");
			$host = $result.HostName;
			$basic =  ($result.connectionType -eq "Basic" -or $result.connectionType -eq "Basic-SSL");
			$protocol = "http://";
			$port = "";

			$result.ClassName = if ($basic) { 'Tridion.ContentManager.CoreService.Client.CoreServiceClient' }
												else { 'Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient' };
			
			switch($result.connectionType)
			{
				"SSL" 		{ $protocol = "https://"; }
				"LDAP-SSL" 	{ $protocol = "https://"; }
				"Basic-SSL" { $protocol = "https://"; }
				"netTcp"	{ $protocol = "net.tcp://"; $port = ":2660"; }
			}
			
			$clientDir = Join-Path $PSScriptRoot 'Clients';

			if ($port)
			{
				$host = (_Get-HostWithoutPort $host);
			}
			
			switch($result.Version)
			{
				"2011-SP1" 
				{ 
					$result.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2011/netTcp" } 
												else { if ($basic) {"/webservices/CoreService2011.svc/basicHttp"} 
												else  { "/webservices/CoreService2011.svc/wsHttp" } };
					$result.EndpointUrl = (@($protocol, $host, $port, $relativeUrl) -join "");
				}
				"2013" 
				{
					$result.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2012/netTcp" } 
												else { if ($basic) {"/webservices/CoreService2012.svc/basicHttp"} 
												else  { "/webservices/CoreService2012.svc/wsHttp" } };
					$result.EndpointUrl = (@($protocol, $host, $port, $relativeUrl) -join "");
				}
				"2013-SP1" 
				{ 
					$result.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2013/netTcp" } 
												else { if ($basic) {"/webservices/CoreService2013.svc/basicHttp"} 
												else  { "/webservices/CoreService2013.svc/wsHttp" } };
					$result.EndpointUrl = (@($protocol, $host, $port, $relativeUrl) -join "");
				}
				"Web-8.1"
				{
					$result.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201501/netTcp" } 
												else { if ($basic) {"/webservices/CoreService201501.svc/basicHttp"} 
												else  { "/webservices/CoreService201501.svc/wsHttp" } };
					$result.EndpointUrl = (@($protocol, $host, $port, $relativeUrl) -join "");
				}
				"Web-8.5"
				{
					$result.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_5.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201603/netTcp" } 
												else { if ($basic) {"/webservices/CoreService201603.svc/basicHttp"} 
												else  { "/webservices/CoreService201603.svc/wsHttp" } };
					$result.EndpointUrl = (@($protocol, $host, $port, $relativeUrl) -join "");
				}
			}
		}
		
		if ($Persist)
		{
			_Persist-Settings $result;
		}
		
		$script:Settings = $result;
		if ($PassThru) 
		{ 
			return $result;
		}
    }
}

Function Clear-TridionCoreServiceSettings
{
    <#
    .Synopsis
    Resets the Core Service settings to the default values.
    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
		[Parameter()]
		[switch]$Persist,
		
		[Parameter()]
		[switch]$PassThru
	)
	
	Process {
        $result = _Get-DefaultSettings
		if ($Persist -and $PSCmdlet.ShouldProcess('CoreServiceSettings.xml'))
		{
			_Persist-Settings $result
		}
		$script:Settings = $result;
		if ($PassThru) 
		{ 
			return $result;
		}
    }
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-Tridion*, Set-Tridion*, Clear-Tridion* -Alias *