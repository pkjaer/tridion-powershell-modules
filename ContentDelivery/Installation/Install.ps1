#Requires -Version 3.0

# Do not continue if there's an error
$ErrorActionPreference = 'Stop';

$branch = 'develop';

# Base URL to download the latest version from the internet
$baseDownloadUrl = "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/${branch}/ContentDelivery";

# List of all the files to install
$directories = @("Installation");
$files = @(
	#'Installation/Verify.ps1',
	'Services.psm1', 
	'Tridion-ContentDelivery.psd1'
);

	
# Download the installation script
wget "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/${branch}/Shared/Installation/Install-ModuleFromWeb.ps1" | iex

# Install the above files and directories
Install-ModuleFromWeb -ModuleName "Tridion-ContentDelivery" -BaseUrl $baseDownloadUrl -Files $files -Directories $directories;