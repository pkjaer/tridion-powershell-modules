#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';


function EnsureDirectoriesExist($moduleName, $directories)
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
	$baseDir = (Join-Path -Path $destination -ChildPath $moduleName);
	
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

function Completed($moduleName)
{
	# Load the new module and report success
	if (Get-Module $moduleName)
	{
		Remove-Module -Force $moduleName | Out-Null;
	}
	Import-Module $moduleName | Out-Null;
	$version = (Get-Module $moduleName).Version.ToString();
	Write-Host "The $moduleName PowerShell module (version $version) has been installed and loaded." -Foreground Green;
}

function ReplaceSlashes([string]$file)
{
	return $file.Replace('/', '\');
}

function Install-ModuleFromWeb($moduleName, $baseDownloadUrl, $files, $directories)
{
	$baseDir = EnsureDirectoriesExist($moduleName, $directories);
	$max = $files.Count;
	$idx = 0;
	
	# Download all of the files
    Write-Host "Downloading $moduleName PowerShell module ($max files)...";
    $net = (New-Object Net.WebClient);
    $net.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials;

	foreach ($file in $files)
	{
		$destination = ReplaceSlashes((Join-Path $baseDir $file));
		$net.DownloadFile("$baseDownloadUrl/$file", $destination);
		Write-Progress -Activity "Downloading module files" -Status $file -PercentComplete ((++$idx / $max) * 100);
	}

	Completed;
}
