#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';

# Base URL to download the latest version from the internet
$baseDownloadUrl = 'https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/master';

# List of all the files to install
$directories = @("Clients", "Installation");
$files = @(
	'Clients/Tridion.ContentManager.CoreService.Client.2011sp1.dll', 
	'Clients/Tridion.ContentManager.CoreService.Client.2013.dll', 
	'Clients/Tridion.ContentManager.CoreService.Client.2013sp1.dll',
	'Installation/Install.ps1',
	'Installation/Verify.ps1',
	'Client.psm1', 
	'Items.psm1', 
	'Settings.psm1', 
	'Tridion-CoreService.psd1', 
	'Trustees.psm1'
);

	
function EnsureDirectoriesExist
{
	# Locate the user's module directory
    $modulePaths = @($env:PSModulePath -split ';');
	$expectedPath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules;
	$destination = $modulePaths | Where-Object { $_ -eq $expectedPath };
	
	if (-not $destination) 
	{
		$destination = $modulePaths | Select-Object -Index 0;
	}

	# Create the module folders
	$baseDir = ($destination + '\Tridion-CoreService');
	
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
	if (Get-Module Tridion-CoreService)
	{
		Remove-Module -Force Tridion-CoreService | Out-Null;
	}
	Import-Module Tridion-CoreService | Out-Null;
	$version = (Get-Module Tridion-CoreService).Version.ToString();
	Write-Host "Tridion PowerShell Modules version $version has been installed and loaded." -Foreground Green;
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
    Write-Host "Downloading Tridion PowerShell Modules ($max files)...";
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
