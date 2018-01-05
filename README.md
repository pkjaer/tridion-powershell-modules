# Tridion PowerShell Modules

This project contains **Windows PowerShell modules** that allow you to easily interact with the **SDL Tridion** / **SDL Web** content management system and perform various administrative tasks.

Currently supported Tridion versions: 2011 SP1, 2013 GA, 2013 SP1, Web 8.1 and Web 8.5.

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
