function VerifyInstallation
{
	Write-Host "Verifying configuration settings...";
	Write-Host ""
	
	if (!(Get-Module Tridion-Alchemy))
	{
		Import-Module Tridion-Alchemy;
	}
	
	$plugins = Get-AlchemyPlugins
	if ($plugins -ne $null)
	{
		Write-Host "Everything appears to be working fine." -Foreground Green;
	}
	else
	{
		$Host.UI.WriteErrorLine("Verification failed. Unable to connect to Alchemy.");
		Write-Host ""
		Write-Host "Please review the current configuration settings:"
		Get-AlchemyConnectionSettings;
		Write-Host ""
		Write-Host "Note: Correct any mistakes you see by calling Set-AlchemyConnectionSettings.";
	}
}

VerifyInstallation;
