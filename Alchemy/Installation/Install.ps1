#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';

# Base URL to download the latest version from the internet
$baseDownloadUrl = 'https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/master/Alchemy';

# List of all the files to install
$directories = @("Installation");
$files = @(
	'Installation/Install.ps1',
	'Installation/Verify.ps1',
	'Plugins.psm1', 
	'Settings.psm1', 
	'Tridion-Alchemy.psd1'
);

	
function EnsureDirectoriesExist
{
	# Locate the user's module directory
    $modulePaths = @($env:PSModulePath -split ';');
	$expectedPath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules;
	$destination = $modulePaths | Where-Object { $_ -eq $expectedPath } | Select -First 1;
	
	if (-not $destination) 
	{
		$destination = $modulePaths | Select-Object -Index 0;
	}

	# Create the module folders
	$baseDir = (Join-Path -Path $destination -ChildPath 'Tridion-Alchemy');
	
	foreach($dir in $directories)
	{
		$path = Join-Path $baseDir $dir;
		New-Item -Path $path -ItemType Directory -Force | Out-Null;
		if (!(Test-Path $path))
		{
			throw "Failed to create module directory: $path";
		}
	}
	
	return $baseDir;
}

function Completed
{
	# Load the new module and report success
	if (Get-Module Tridion-Alchemy)
	{
		Remove-Module -Force Tridion-Alchemy | Out-Null;
	}
	Import-Module Tridion-Alchemy | Out-Null;
	$version = (Get-Module Tridion-Alchemy).Version.ToString();
	Write-Host "The Tridion-Alchemy PowerShell module (version $version) has been installed and loaded." -Foreground Green;
}

function ReplaceSlashes([string]$file)
{
	return $file.Replace('/', '\');
}

function DownloadAndInstall 
{
	$baseDir = EnsureDirectoriesExist;
	$max = $files.Count;
	$idx = 0;
	
	# Download all of the files
    Write-Host "Downloading Tridion-Alchemy PowerShell module ($max files)...";
    $net = (New-Object Net.WebClient);
    $net.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials;

	foreach ($file in $files)
	{
		$destination = ReplaceSlashes((Join-Path $baseDir $file));
		$net.DownloadFile("$baseDownloadUrl/$file", $destination);
		Write-Progress -Activity "Downloading module files" -Status "$file" -PercentComplete ((++$idx / $max) * 100);
	}

	Completed;
}

DownloadAndInstall;
