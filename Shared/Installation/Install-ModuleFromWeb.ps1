#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';


function EnsureDirectoriesExist($ModuleName, $Directories)
{
	# Locate the user's module directory
    $modulePaths = @($env:PSModulePath -Split ';');
	$expectedPath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules';
	$destination = $modulePaths | Where-Object { $_ -eq $expectedPath } | Select -First 1;
	
	if (-not $destination) 
	{
		$destination = $modulePaths | Select-Object -Index 0;
	}

	# Create the module folders
	$baseDir = (Join-Path -Path $destination -ChildPath $ModuleName);
	
	foreach($dir in $Directories)
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

function Completed($ModuleName)
{
	# Load the new module and report success
	if (Get-Module $ModuleName)
	{
		Remove-Module -Force $ModuleName | Out-Null;
	}
	Import-Module $ModuleName | Out-Null;
	$version = (Get-Module $ModuleName).Version.ToString();
	Write-Host "The $ModuleName PowerShell module (version $version) has been installed and loaded." -Foreground Green;
}

function ReplaceSlashes([string]$file)
{
	return $file.Replace('/', '\');
}

function Install-ModuleFromWeb([string]$ModuleName, [string]$BaseUrl, $Files, $Directories)
{
	$baseDir = EnsureDirectoriesExist($ModuleName, $Directories);
	$max = $Files.Count;
	$idx = 0;
	
	# Download all of the files
    Write-Host "Downloading $ModuleName PowerShell module ($max files)...";
    $net = (New-Object Net.WebClient);
    $net.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials;

	foreach ($file in $Files)
	{
		$destination = ReplaceSlashes((Join-Path $baseDir $file));
		$net.DownloadFile("$BaseUrl/$file", $destination);
		Write-Progress -Activity "Downloading module files" -Status $file -PercentComplete ((++$idx / $max) * 100);
	}

	Completed;
}
