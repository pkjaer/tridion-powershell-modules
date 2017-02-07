#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

Function Add-Property($Object, $Name, $Value)
{
	Add-Member -InputObject $Object -MemberType NoteProperty -Name $Name -Value $Value;
}

Function Has-Property($Object, $Name)
{
	return Get-Member -InputObject $Object -Name $Name -MemberType NoteProperty;
}

Function Add-SettingIfMissing($Object, $Name, $Value)
{
	if (!(Has-Property -Object $Object -Name $Name))
	{
		Add-Property $Object $Name $Value;
		Write-Host -ForegroundColor Green "There is a new setting available: $Name. The default value of '$Value' has been applied."
	}
}

Function New-ObjectWithProperties([Hashtable]$properties)
{
	$result = New-Object -TypeName System.Object;
	foreach($key in $properties.Keys)
	{
		Add-Property -Object $result -Name $key -Value $properties[$key];
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
		"ConnectionSendTimeout" = "00:01:00";
		"HostName" = "localhost";
		"UserName" = ([Environment]::UserDomainName + "\" + [Environment]::UserName);
        "Password" = "";
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
		Add-SettingIfMissing -Object $settings -Name 'ConnectionSendTimeout' -Value '00:01:00';
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
			
            #todo Find a more elegant way to prevent saving the password to the settings file
            $password = $settings.Password
            $settings.Password = ""
			Export-Clixml -Path $settingsFile -InputObject $settings;
    		$settings.Password = $password
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
		
		[ValidateSet('', '2011-SP1', '2013', '2013-SP1', 'Web-8.1', 'Web-8.2', 'Web-8.3')]
		[string]$Version,
		
		[Parameter()]
		[string]$UserName,
		
		[Parameter()]
		[string]$Password,
		
		[ValidateSet('', 'Default', 'SSL', 'LDAP', 'LDAP-SSL', 'netTcp', 'BASIC', 'BASIC-SSL')]
		[Parameter()]
		[string]$ConnectionType,
		
		[Parameter()]
		[string]$ConnectionSendTimeout,
		
		[Parameter()]
		[switch]$Persist
    )

    Process
    {
		$hostNameSpecified = (![string]::IsNullOrEmpty($HostName));
		$userNameSpecified = (![string]::IsNullOrEmpty($UserName));
        $passwordSpecified = (![string]::IsNullOrEmpty($Password));
		$versionSpecified = (![string]::IsNullOrEmpty($Version));
		$connectionTypeSpecified = (![string]::IsNullOrEmpty($ConnectionType));
		$connectionSendTimeoutSpecified = (![string]::IsNullOrEmpty($ConnectionSendTimeout));
		
		$settings = Get-Settings;
		if ($connectionTypeSpecified) { $settings.ConnectionType = $ConnectionType; }
		if ($connectionSendTimeoutSpecified) { $settings.ConnectionSendTimeout = $ConnectionSendTimeout; }
		if ($hostNameSpecified) { $settings.HostName = $HostName; }
		if ($userNameSpecified) { $settings.UserName = $UserName; }
        if ($passwordSpecified) { $settings.Password = $Password; }
		if ($versionSpecified) { $settings.Version = $Version; }

		if ($versionSpecified -or $hostNameSpecified -or $connectionTypeSpecified)
		{
			$netTcp =  ($settings.connectionType -eq "netTcp");
			$basic =  ($settings.connectionType -eq "BASIC" -or $settings.connectionType -eq "BASIC-SSL");
			$protocol = "http://";
			$port = "";

			$settings.ClassName = if ($basic) {"Tridion.ContentManager.CoreService.Client.CoreServiceClient"} else  { "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient" } 

			switch($settings.connectionType)
			{
				"SSL" 		{ $protocol = "https://"; }
				"LDAP-SSL" 	{ $protocol = "https://"; }
				"BASIC-SSL" { $protocol = "https://"; }
				"netTcp"	{ $protocol = "net.tcp://"; $port = ":2660"; }
			}
			
			$clientDir = Join-Path $PSScriptRoot 'Clients'
			
			switch($settings.Version)
			{
				"2011-SP1" 
				{ 
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2011sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2011/netTcp" } else { if ($basic) {"/webservices/CoreService2011.svc/basicHttp"} else  { "/webservices/CoreService2011.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"2013" 
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2012/netTcp" } else { if ($basic) {"/webservices/CoreService2012.svc/basicHttp"} else  { "/webservices/CoreService2012.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"2013-SP1" 
				{ 
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.2013sp1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/2013/netTcp" } else { if ($basic) {"/webservices/CoreService2013.svc/basicHttp"} else  { "/webservices/CoreService2013.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"Web-8.1"
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_1.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201501/netTcp" } else { if ($basic) {"/webservices/CoreService201501.svc/basicHttp"} else  { "/webservices/CoreService201501.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"Web-8.2"
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_2.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201601/netTcp" } else { if ($basic) {"/webservices/CoreService201601.svc/basicHttp"} else  { "/webservices/CoreService201601.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"Web-8.3"
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_3.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201603/netTcp" } else { if ($basic) {"/webservices/CoreService201603.svc/basicHttp"} else { "/webservices/CoreService201603.svc/wsHttp" } };
					$settings.EndpointUrl = (@($protocol, $settings.HostName, $port, $relativeUrl) -join "");
				}
				"Web-8.5"
				{
					$settings.AssemblyPath = Join-Path $clientDir 'Tridion.ContentManager.CoreService.Client.Web_8_5.dll';
					$relativeUrl = if ($netTcp) { "/CoreService/201605/netTcp" } else { if ($basic) {"/webservices/CoreService201605.svc/basicHttp"} else  { "/webservices/CoreService2016035.svc/wsHttp" } };
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

Function Clear-CoreServiceSettings
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
	
	Process {
        $settings = Get-DefaultSettings
        Save-Settings $settings
    }
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-CoreServiceSettings;
Export-ModuleMember Set-CoreServiceSettings;
Export-ModuleMember Clear-CoreServiceSettings;
