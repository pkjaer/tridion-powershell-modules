#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';

$branch = 'develop';

# Base URL to download the latest version from the internet
$baseDownloadUrl = "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/${branch}/CoreService";

# List of all the files to install
$directories = @("Clients", "Installation");
$files = @(
	'Clients/Tridion.ContentManager.CoreService.Client.2011sp1.dll', 
	'Clients/Tridion.ContentManager.CoreService.Client.2013.dll', 
	'Clients/Tridion.ContentManager.CoreService.Client.2013sp1.dll',
	'Clients/Tridion.ContentManager.CoreService.Client.Web_8_1.dll',
	'Clients/Tridion.ContentManager.CoreService.Client.Web_8_2.dll',
	'Installation/Verify.ps1',
	'AppData.psm1', 
	'Client.psm1', 
	'Items.psm1', 
	'Settings.psm1', 
	'Tridion-CoreService.psd1', 
	'Trustees.psm1'
);


# Download the installation script
wget "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/${branch}/Shared/Installation/Install-ModuleFromWeb.ps1" | iex

# Install the above files and directories
Install-ModuleFromWeb -ModuleName "Tridion-CoreService" -BaseUrl $baseDownloadUrl -Files $files -Directories $directories;