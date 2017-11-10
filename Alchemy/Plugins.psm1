#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>
Function GetClient([PSCredential]$Credentials)
{
	if ($script:Client)
	{
		return $script:Client;
	}
	
	$client = New-Object System.Net.WebClient;
	
	if ($Credentials -ne $null)
	{
		Write-Verbose "Logging on using the provided credentials...";
		$client.UseDefaultCredentials = $false;
		$client.Credentials = $Credentials;
	} 
	else 
	{
		Write-Verbose "Logging on as the current user...";
		$client.UseDefaultCredentials = $true;
	}
	
	$script:Client = $client;
	return $client;
}


Function NormalizeServerUrl([string]$Host)
{
	$result = "http://localhost/";
	if ([string]::IsNullOrWhitespace($Host) -eq $false)
	{
		$result = $Host.Trim();
	
		if ($result.StartsWith("http") -eq $false)
		{
			$result = "http://$result";
		}

		if ($result.EndsWith("/") -eq $false)
		{
			$result = $result + "/";
		}
	}
	
	return $result;
}

Function GetMonitorJobs($Folder = $null)
{
	$jobs = Get-Job | Where-Object { $_.Name.StartsWith("PluginChanged_") };
	
	if (($jobs.Count -gt 0) -and ($Folder -ne $null))
	{
		return $jobs | Where-Object { $Folder.StartsWith($_.Name.Substring(14) + '\') };
	}

	return $jobs;
}



<#
**************************************************
* Public members
**************************************************
#>

Function Get-AlchemyPluginNameFromFile
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
		[string]$File
	)

	Begin
	{
        Add-Type -assembly System.IO.Compression.FileSystem;
	}
	
	Process
	{
		if (!(Test-Path($File)))
		{
			throw "The file '$File' does not exist.";
		}
		
		if (!($File.EndsWith(".a4t")))
		{
			throw "The file '$File' is not a valid Alchemy Plugin (.a4t) file.";
		}
		
        $zip = Get-Item($File);
		$a = [IO.Compression.ZipFile]::OpenRead($zip.FullName);
        $entries = $a.Entries | Where-Object {$_.FullName -eq "a4t.xml"};
		
		if ($entries.Count -lt 1)
		{
			throw "The file '$File' is not a valid Alchemy Plugin (.a4t) file.";
		}

        $stream = $entries[0].Open();
        $reader = New-Object System.IO.StreamReader($stream);
        $content = [xml] $reader.ReadToEnd();
		
		$stream.Dispose();
		$reader.Dispose();
		$a.Dispose();
		return [string]$content.plugin.name;
	}
}

Function Get-AlchemyPlugins
{
    [CmdletBinding()]
    Param()
	
	Process
	{
		$settings = Get-AlchemyConnectionSettings;
		$client = GetClient -Credentials $settings.Credentials;
		$server = NormalizeServerUrl $settings.Host;
		
		Write-Verbose "Getting list of plugins from '$server'";
		
		$response = $client.DownloadString($server + "Alchemy/api/Plugins");
		if ($response -eq $null)
		{
			return $null;
		}
		
		return ConvertFrom-Json($response);
	}
}

Function Install-AlchemyPlugin
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
		[string]$File,
		
		[Parameter()]
		[switch]$Force
	)
	
	Process
	{
		$verboseRequested = ($PSBoundParameters['Verbose'] -eq $true);
		$settings = Get-AlchemyConnectionSettings;
		
		$name = Get-AlchemyPluginNameFromFile $File
		$nameWithSpaces = $name.Replace('_', ' ');

		if (!$Force)
		{
			$installedPlugins = Get-AlchemyPlugins -Verbose:$verboseRequested | Where-Object { $_.name -eq $nameWithSpaces };
			if ($installedPlugins.Count -gt 0)
			{
				Write-Warning "'$nameWithSpaces' is already installed.";
				return;
			}
		}
		
		$client = GetClient -Credentials $settings.Credentials -Verbose:$verboseRequested;
		$server = NormalizeServerUrl $settings.Host -Verbose:$verboseRequested;
		
		$url = $server + "Alchemy/api/Plugins/Install";
		$file = Get-Item $File;
		
		$client.UploadFile($url, $file) | Out-Null;
		Write-Output "'$nameWithSpaces' has been installed.";
	}
}

Function Uninstall-AlchemyPlugin
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, ParameterSetName='UsingFileName')]
		[string]$File,
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, ParameterSetName='UsingName')]
		[string]$Name,
		
        [Parameter(ParameterSetName='UsingFileName')]
        [Parameter(ParameterSetName='UsingName')]
		[switch]$Force
	)
	
	Process
	{
		$verboseRequested = ($PSBoundParameters['Verbose'] -eq $true);
		$settings = Get-AlchemyConnectionSettings;
		$name = $Name;
		
		if ($File)
		{
			Write-Verbose "Reading the plugin name from file...";
			$name = Get-AlchemyPluginNameFromFile $File -Verbose:$verboseRequested;
		}
		$nameWithSpaces = $name.Replace('_', ' ');

		if (!$Force)
		{
			$installedPlugins = Get-AlchemyPlugins -Verbose:$verboseRequested | Where-Object { $_.name -eq $nameWithSpaces };
			if ($installedPlugins.Count -lt 1)
			{
				Write-Verbose "'$nameWithSpaces' is not currently installed.";
				return;
			}
		}
		
		$client = GetClient -Credentials $settings.Credentials -Verbose:$verboseRequested;
		$server = NormalizeServerUrl $settings.Host -Verbose:$verboseRequested;
		$escapedName = $name.Replace(' ', '_');
		
		$url = $server + "Alchemy/api/Plugins/$escapedName/Uninstall";
		$client.UploadString($url, "{}") | Out-Null;
		Write-Output "'$nameWithSpaces' has been uninstalled.";
	}
}

Function Update-AlchemyPlugin
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
		[string]$File,
		
		[Parameter()]
		[switch]$Force
	)
	
	Process
	{
		$verboseRequested = ($PSBoundParameters['Verbose'] -eq $true);
		
		try
		{
			Write-Progress -Activity "Updating plugin" -Status "Uninstalling $File" -PercentComplete 10;
			Uninstall-AlchemyPlugin -File $File -Verbose:$verboseRequested -Force:$Force
			Write-Progress -Activity "Updating plugin" -Status "Uninstalling $File" -PercentComplete 50;
			Install-AlchemyPlugin -File $File -Verbose:$verboseRequested -Force:$Force
			Write-Progress -Activity "Updating plugin" -Status "Done updating $File" -PercentComplete 10 -Completed;
		}
		catch
		{
			Write-Progress -Activity "Updating plugin" -Status "Failed" -Completed;
			Write-Error $_.Error;
		}
}
}

Function Start-AlchemyPluginMonitor
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
		[string]$Folder,
		
		[Parameter()]
		[switch]$Force
	)
	
	Process
	{
		$jobs = GetMonitorJobs -Folder $Folder;
		if ($jobs.Count -gt 0)
		{
			Write-Warning("You are already monitoring $Folder...");
			return;
		}
		
		$filter = '*.a4t';
		$watcher = New-Object IO.FileSystemWatcher $Folder, $filter -Property @{IncludeSubdirectories = $true; NotifyFilter = [IO.NotifyFilters]'FileName, DirectoryName, LastWrite'}
		$messageData = New-Object PSObject -Property @{Verbose = ($PSBoundParameters['Verbose'] -eq $true); Force = $Force}
		
		$onChange = {
			$fileName = $Event.SourceEventArgs.FullPath;
			$timeStamp = $Event.TimeGenerated 
			$messageData = $Event.MessageData;
			$elapsed = New-Object System.TimeSpan;
			$force = $messageData.Force;
			$update = ($lastTime -eq $null);
			
			if (!$update)
			{
				$elapsed = ($timeStamp - $lastTime);
				$update = ($elapsed.Seconds -gt 1) -or ($lastFileName -ne $fileName);
			}
			
			$lastTime = $timeStamp;
			$lastFileName = $fileName;
			
			if ($update)
			{
				Update-AlchemyPlugin -File $fileName -Verbose:$messageData.Verbose -Force:$force
			}
		};

		Register-ObjectEvent $watcher Changed -SourceIdentifier "PluginChanged_$Folder" -Action $onChange -MessageData $messageData | Out-Null;
		Write-Output "Now monitoring plugin changes in '$Folder'..."

	}
}

Function Stop-AlchemyPluginMonitor
{
    [CmdletBinding()]
    Param()
	
	Process
	{
		$jobs = GetMonitorJobs;
		$count = $jobs.Count;
		if ($count -gt 0)
		{
			Write-Verbose "Stopping $count job(s)...";
			$jobs | Remove-Job -Force
			Write-Output "Stopped monitoring for plugin changes.";
		}
		else
		{
			Write-Verbose "There is no monitoring going on at the moment.";
		}
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-AlchemyPluginNameFromFile
Export-ModuleMember Get-AlchemyPlugins
Export-ModuleMember Install-AlchemyPlugin
Export-ModuleMember Uninstall-AlchemyPlugin
Export-ModuleMember Update-AlchemyPlugin
Export-ModuleMember Start-AlchemyPluginMonitor
Export-ModuleMember Stop-AlchemyPluginMonitor