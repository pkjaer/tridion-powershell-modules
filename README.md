# Tridion PowerShell Modules

This project contains **Windows PowerShell modules** that allow you to easily interact with the **SDL Tridion** / **SDL Web** content management system and perform various administrative tasks.

Currently supported Tridion versions: 2011 SP1, 2013 GA, 2013 SP1, Web 8.1, Web 8.5, Sites 9.0 (and basic support for 9.5 too -- [see below](#A-note-on-upgrades-and-versions)).

## Installation

The modules are available on PowerShell Gallery. As such, they can be installed using the `Install-Module` cmdlet.

~~~~PowerShell
Install-Module -Name Tridion-CoreService 
~~~~

*_Note:_* if you are using an older version of PowerShell (less than version 5), you will need to install [PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/psget/overview) first.

After the installation is complete, import the module(s) using `Import-Module` to use the features.

~~~~PowerShell
Import-Module -Name Tridion-CoreService
~~~~

Should the above steps fail to work for you, please [let us know](https://github.com/pkjaer/tridion-powershell-modules/issues/new)!

## Help

You can get the list of all of the commands by typing this in PowerShell:
`Get-Command -Module Tridion-*`

Each command also has help information available (including examples), which you can read by calling `Get-Help nameOfCommand` (e.g. `Get-Help Get-TridionUser`).

If you have any issues or questions, feel free to add an entry under [Issues](https://github.com/pkjaer/tridion-powershell-modules/issues).


## A note on upgrades and versions
Each version of the suite continues to support the Core Service endpoints for the past couple of versions. Because of that, you don't _always_ have to match the version used in the modules with the version of the suite you have. You can use a slightly older "version" without issues. 

The only reason why you _have_ to use a specific version is if you have custom code using the client returned by Get-TridionCoreServiceClient _and_ you need to use a property or method introduced in a newer version. 

In other words, you don't always need to migrate your scripts immediately as part of an upgrade of the suite -- though you'll want to ensure you don't fall too far behind (e.g. you cannot use 2013 endpoints in 9.0).

This also means that you can use version 9.0 in the modules when connecting to a Sites 9.5 system (which doesn't have its own version in the modules yet).
