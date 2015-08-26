#Requires -version 3.0

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
			Write-Error "Failed to save your settings for next time. Perhaps you don't have permissions to modify '$settingsFile'?";
		}
	}
}

<#
**************************************************
* Public members
**************************************************
#>

Function Get-CoreServiceSettings
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
	
	Process { return Get-Settings; }
}

Function Set-CoreServiceSettings
{
    <#
    .Synopsis
    Changes the settings used to connect to the Core Service.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Set-TridionCoreServiceSettings -HostName "machine.domain" -Version "2013-SP1" -ConnectionType netTcp
	Makes the module connect to a Core Service hosted on "machine.domain", using netTcp bindings and the 2013 SP1 version of the service.
	
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
		[ValidateNotNullOrEmpty()]
        [string]$HostName,
		
		[ValidateSet('', '2011-SP1', '2013', '2013-SP1')]
		[string]$Version,
		
		[Parameter()]
		[string]$UserName,
		
		[ValidateSet('', 'Default', 'SSL', 'LDAP', 'LDAP-SSL', 'netTcp')]
		[Parameter()]
		[string]$ConnectionType,
		
		[Parameter()]
		[switch]$Persist
    )

    Process
    {
		$hostNameSpecified = (![string]::IsNullOrEmpty($HostName));
		$userNameSpecified = (![string]::IsNullOrEmpty($UserName));
		$versionSpecified = (![string]::IsNullOrEmpty($Version));
		$connectionTypeSpecified = (![string]::IsNullOrEmpty($ConnectionType));
		
		$settings = Get-Settings;
		if ($connectionTypeSpecified) { $settings.ConnectionType = $ConnectionType; }
		if ($hostNameSpecified) { $settings.HostName = $HostName; }
		if ($userNameSpecified) { $settings.UserName = $UserName; }
		if ($versionSpecified) { $settings.Version = $Version; }

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
		
		if ($Persist)
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
Export-ModuleMember Get-CoreServiceSettings;
Export-ModuleMember Set-CoreServiceSettings;
