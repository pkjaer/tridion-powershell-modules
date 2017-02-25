#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';

<#
**************************************************
* Private members
**************************************************
#>

Function EnsureDirectoriesExist([string]$ModuleName, $Directories)
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

Function Completed([string]$ModuleName)
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

Function ReplaceSlashes([string]$File)
{
	return $File.Replace('/', '\');
}


<#
**************************************************
* Public members
**************************************************
#>

Function Install-ModuleFromWeb
{
    <#
    .Synopsis
    Downloads and installs a PowerShell module from the specified URL.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	#>
    [CmdletBinding()]
    Param
	(
		# The name of the module
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$ModuleName,
		
		# The base URL to download the files from. The -Files entries will be relative to this URL.
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$BaseUrl,

		# The full list of files to install.
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string[]]$Files,
		
		# A list of directories to create. If -Files contains relative sub-directories they must be included in this parameter.
        [Parameter(Mandatory=$false)]
        [string[]]$Directories	
	)
	
	Process 
	{ 
		$baseDir = EnsureDirectoriesExist -ModuleName $ModuleName -Directories $Directories;
		$max = $Files.Count;
		$idx = 0;
		
		# Download all of the files
		Write-Host "Downloading $ModuleName PowerShell module ($max files)...";
		$net = (New-Object Net.WebClient);
		$net.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials;

		foreach ($file in $Files)
		{
			$source = $BaseUrl + '/' + $file;
			$destination = ReplaceSlashes -File (Join-Path -Path $baseDir -ChildPath $file);
			try
			{
				$net.DownloadFile($source, $destination);
			}
			catch
			{
				$errorMessage = $_.Exception.Message;
				throw "Failed to download the file: '$source' to destination '$destination'. Reason: $errorMessage";
			}
			
			Write-Progress -Activity "Downloading module files" -Status $file -PercentComplete ((++$idx / $max) * 100);
		}

		Completed -ModuleName $ModuleName;
	}
}
