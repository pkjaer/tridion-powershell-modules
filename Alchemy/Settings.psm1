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
	$moduleVersion = (Get-Module Tridion-Alchemy).Version;
	return New-ObjectWithProperties @{
		"Host" = "localhost";
		"Credentials" = $null;
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
	return (Get-Module Tridion-Alchemy).Version;
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
	$settingsFile = Join-Path $settingsDir 'AlchemySettings.xml';
	
	if (Test-Path $settingsFile)
	{
		try
		{
			return Convert-OldSettings (Import-Clixml $settingsFile);
		}
		catch
		{
			Write-Host -ForegroundColor Red "Failed to load your existing settings. Using the default settings. "; 
		}
	}
	return Get-DefaultSettings;
}

Function Save-Settings($settings)
{
	if ($settings -ne $null)
	{
		$settingsDir = Join-Path $PSScriptRoot 'Settings'
		$settingsFile = Join-Path $settingsDir 'AlchemySettings.xml';
		
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

Function Get-ConnectionSettings
{
    <#
    .Synopsis
    Gets the settings used to talk to Alchemy 4 Tridion.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	#>
    [CmdletBinding()]
    Param()
	
	Process { return Get-Settings; }
}

Function Set-ConnectionSettings
{
    <#
    .Synopsis
    Changes the settings used to talk to Alchemy 4 Tridion.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Set-AlchemyConnectionSettings -Host "machine.domain"
	Makes the module connect to Alchemy on "machine.domain" for this session.
	
    Set-AlchemyConnectionSettings -Host "machine.domain" -Persist
	Makes the module connect to Alchemy on "machine.domain" and stores it as a default for future sessions.
	
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter()]
		[ValidateNotNullOrEmpty()]
        [string]$Host,
		
		[Parameter()]
		[PSCredential]$Credentials,
		
		[Parameter()]
		[switch]$Persist
    )

    Process
    {
		$hostSpecified = (![string]::IsNullOrEmpty($Host));
		$credentialsSpecified = ($Credentials -ne $null);
		$settings = Get-Settings;
		if ($hostSpecified) { $settings.Host = $Host; }
		if ($credentialsSpecified) { $settings.Credentials = $Credentials; }

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
Export-ModuleMember Get-ConnectionSettings;
Export-ModuleMember Set-ConnectionSettings;
