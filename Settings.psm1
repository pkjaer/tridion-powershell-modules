#Requires -version 2.0

$ErrorActionPreference = "Stop";

<#
**************************************************
* Private members
**************************************************
#>

Function Add-Property($object, $name, $value)
{
	Add-Member -InputObject $object -membertype NoteProperty -name $key -value $value;
}

Function New-ObjectWithProperties([Hashtable]$properties)
{
	$result = New-Object -TypeName System.Object;
	foreach($key in $properties.Keys)
	{
		Add-Property $result $key $properties[$key];
	}
	return $result;
}

Function Get-DefaultSettings
{
	$clientDir = Join-Path $PSScriptRoot 'Clients';
	$moduleVersion = (Get-Module Tridion-CoreService).Version;
	return New-ObjectWithProperties @{
		"AssemblyPath" = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll';
		"ClassName" = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
		"EndpointUrl" = "http://localhost/webservices/CoreService2011.svc/wsHttp";
		"HostName" = "localhost";
		"UserName" = ([Environment]::UserDomainName + "\" + [Environment]::UserName);
		"Version" = "2011-SP1";
		"ConnectionType" = "Default";
		"ModuleVersion" = $moduleVersion;
	};
}

Function Get-Settings
{
	if ($script:Settings -eq $null)
	{
		$script:Settings = Restore-Settings;
	}
	
	return $script:Settings;
}

Function Get-ModuleVersion
{
	return (Get-Module Tridion-CoreService).Version;
}

Function Convert-OldSettings($settings)
{
	$moduleVersion = Get-ModuleVersion
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
		$settings.ModuleVersion = $moduleVersion;
		Save-Settings $settings;
	}
	return $settings;
}

Function Restore-Settings
{
	$settingsDir = Join-Path $PSScriptRoot 'Settings'
	$settingsFile = Join-Path $settingsDir 'CoreServiceSettings.xml';
	
	if (Test-Path $settingsFile)
	{
		try
		{
			return Convert-OldSettings (Import-Clixml $settingsFile);
		}
		catch
		{
			Write-Host -ForegroundColor Red "Failed to load your existing settings. Using the default settings. "; 
			return Get-DefaultSettings;
		}
	}
	return Get-DefaultSettings;
}

Function Save-Settings($settings)
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
			
			Export-Clixml -Path $settingsFile -InputObject $settings;
			$script:Settings = $settings;
		}
		catch
		{
			Write-Host -ForegroundColor Red "Failed to save your settings for next time.";
			Write-Host -ForegroundColor Red "Perhaps you don't have permissions to modify '$settingsFile'?";
		}
	}
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
    https://code.google.com/p/tridion-powershell-modules/
	#>
    [CmdletBinding()]
    Param()
	
	Process { return Get-Settings; }
}

Function Set-TridionCoreServiceSettings
{
    <#
    .Synopsis
    Changes the settings used to connect to the Core Service.

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    Set-TridionCoreServiceSettings -hostName "machine.domain" -version "2013-SP1" -connectionType netTcp
	
	Makes the module connect to a Core Service hosted on "machine.domain", using netTcp bindings and the 2013 SP1 version of the service.
	
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]$hostName,
		
		[ValidateSet('', '2011-SP1', '2013', '2013-SP1')]
		[string]$version,
		
		[Parameter()]
		[string]$userName,
		
		[ValidateSet('', 'Default', 'SSL', 'LDAP', 'LDAP-SSL', 'netTcp')]
		[Parameter()]
		[string]$connectionType,
		
		[Parameter()]
		[switch]$persist
    )

    Process
    {
		$hostNameSpecified = (![string]::IsNullOrEmpty($hostName));
		$userNameSpecified = (![string]::IsNullOrEmpty($userName));
		$versionSpecified = (![string]::IsNullOrEmpty($version));
		$connectionTypeSpecified = (![string]::IsNullOrEmpty($connectionType));
		
		$settings = Get-Settings;
		if ($connectionTypeSpecified) { $settings.ConnectionType = $connectionType; }
		if ($hostNameSpecified) { $settings.HostName = $hostName; }
		if ($userNameSpecified) { $settings.UserName = $userName; }
		if ($versionSpecified) { $settings.Version = $version; }

		if ($versionSpecified -or $hostNameSpecified -or $connectionTypeSpecified)
		{
			$netTcp =  ($settings.connectionType -eq "netTcp");
			$protocol = "http://";
			$port = "";
			
			switch($settings.connectionType)
			{
				"SSL" 		{ $protocol = "https://"; }
				"LDAP-SSL" 	{ $protocol = "https://"; }
				"netTcp"	{ $protocol = "net.tcp://"; $port = ":2660"; }
			}
			
			$clientDir = Join-Path $PSScriptRoot 'Clients'
			
			switch($settings.Version)
			{
				"2011-SP1" 
				{ 
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2011/netTcp" } else { "/webservices/CoreService2011.svc/wsHttp" };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"2013" 
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2012/netTcp" } else { "/webservices/CoreService2012.svc/wsHttp" };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"2013-SP1" 
				{ 
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2013/netTcp" } else { "/webservices/CoreService2013.svc/wsHttp" };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
			}
		}
		
		if ($persist)
		{
			Save-Settings $settings;
		}
    }
}


<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-TridionCoreServiceSettings;
Export-ModuleMember Set-TridionCoreServiceSettings;
