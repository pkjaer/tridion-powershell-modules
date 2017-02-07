### Tridion-CoreService module

This module contains cmdlets that allow you to talk to the Tridion Content Manager using the Core Service.


### Installation
[Click here to view the installation instructions](https://github.com/pkjaer/tridion-powershell-modules/), which cover installation of all of the modules.


### Release notes

v2.2.0.1
- Added support for Web 8.3-5

v2.2.0.0

- Added these release notes.
- Added support for disabling and enabling users (Disable-TridionUser, Enable-TridionUser). 
  Both of them support piping in UserData objects from other commands like Get-TridionUsers.
- Added support for getting a list of Publication Targets (Get-TridionPublicationTargets)
- Added support for reading Publication Targets and Groups (Get-TridionPublicationTarget, Get-TridionGroup). 
  Both methods support loading the items either by TCM URI or the Title of the item.
- Added support for reading a user by Title or Description.
- Added Test-TridionItem, which returns a boolean indicating if the item exists in the Content Manager.
- Added a new configuration setting called 'ConnectionSendTimeout', which controls the amount of time to wait for a connection before timing out.


v2.1.0.0

- Added support for managing application data (Get-TridionApplicationData, Set-TridionApplicationData, Remove-TridionApplicationData). 
- New-TridionUser now supports adding the user to any number of groups, through the -MemberOf parameter. The scope of the groups is 'All Publications'.


v2.0.3.0

- Added support for SDL Web 8
- Get-TridionCoreServiceClient will now show an error if you have previously loaded a different version of the client (thanks, Dominic Cronin!)


v2.0.2.0

- Fixed an issue detecting the module path when the user had multiple matching directories under 'My Documents'.


v2.0.1.0

- Fixed an issue with the module path for installation.


v2.0.0.0

- Now officially requires PowerShell 3.0
- Introduced a new Close-TridionCoreServiceClient method to simplify properly closing the client.
- The Core Service Client assembly is no longer locked by the PowerShell process.
- Introduced scripts to simplify installation and updates, as well as verifying that it works.


v1.0.3.1

- Updated links after migration to GitHub.


v1.0.3.0

- Better pipeline support (including more sensible logging).
- Ability to overwrite the prefix used in the commands. 
  For example, "Import-Module Tridion-CoreService -Prefix Tri" will result in commands like "New-TriUser" and "Get-TriPublications".
- Improved validation and documentation of parameters.
- Added -WhatIf and -Confirm support to cmdlets that save data (e.g. New-TridionUser)
- Get-TridionPublications: You can now filter by publication type (e.g. "Web" or "Mobile")
- Get-TridionUsers: System users are no longer returned by default (use the -IncludePredefinedUsers switch if you need them)
- New-TridionUser: The isAdmin parameter has been renamed to MakeAdministrator and is now a switch.
- Get-TridionCoreServiceClient: Added an optional parameter to  to overwrite the user to impersonate (can be used in a pipeline).


v1.0.2.0
- Added checks for $null before calling Close on the Core Service client.
- Changed the TransactionProtocol and SecurityModel property to use the enumerations instead of strings (the conversion didn't work for everyone).
- Removed the unused Utilities.psm1 file.
- Split the module into several files with their own distinct functional areas.
- Added the module version to the settings (for information and for future automatic upgrade of settings stored on disk)
- Moved the settings file to a new 'Settings' directory (created as needed) and the DLLs to a 'Clients' folder.


v1.1.0.0
- Removed support for the "2010" endpoint.
- Consolidated all settings into a single Set-TridionCoreServiceSettings method.
- The settings can now be persisted to disk so you don't have to set them every time.
- Added support for netTcp (and made a start for the support of SSL and LDAP).
- Added a New-TridionGroup method to create Groups in the Content Manager.
- Fixed the link to the latest version of the script.


v1.0.1.0

- Added support for 2013 SP1.
- Added support for impersonation of users.
- Fixed Get-TridionPublications not outputting verbose text when prompted to.


v1.0.0.0

- Initial version of the Tridion PowerShell Modules.