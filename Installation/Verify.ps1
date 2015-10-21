function VerifyInstallation
{
	Write-Host "Verifying configuration settings...";
	Write-Host ""
	
	if (!(Get-Module Tridion-CoreService))
	{
		Import-Module Tridion-CoreService;
	}
	
	$user = Get-TridionUser -ErrorAction SilentlyContinue
	if ($user)
	{
		Write-Host "Everything appears to be working fine." -Foreground Green;
	}
	else
	{
		$Host.UI.WriteErrorLine("Verification failed. Unable to log into Tridion.");
		Write-Host ""
		Write-Host "Please review the current configuration settings:"
		Get-TridionCoreServiceSettings;
		Write-Host ""
		Write-Host "Note: Correct any mistakes you see by calling Set-TridionCoreServiceSettings.";
	}
}

VerifyInstallation;
