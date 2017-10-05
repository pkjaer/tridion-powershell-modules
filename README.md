This project contains **Windows PowerShell modules** that allow you to easily interact with the **SDL Tridion** / **SDL Web** content management system and perform various administrative tasks.

Currently supported Tridion versions: 2011 SP1, 2013 GA, 2013 SP1 and Web 8.


### Installation
The quickest way to install is to use the provided script:

1. Open a Windows PowerShell (v3.0+) console. 
2. Ensure that you can run unsigned local scripts, by calling `Set-ExecutionPolicy`. We recommend the `RemoteSigned` policy. See [Using the Set-ExecutionPolicy Cmdlet](http://technet.microsoft.com/en-us/library/ee176961.aspx) for more information.
3. Start the installation by executing the following line:

`iwr "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/develop/CoreService/Installation/Install.ps1" | iex`

And if you wish to get the Tridion-Alchemy module as well (for managing and developing Alchemy plugins):

`iwr "https://raw.githubusercontent.com/pkjaer/tridion-powershell-modules/develop/Alchemy/Installation/Install.ps1" | iex`

This will download the latest release, install it, and load the modules.
Afterwards, you may wish to run the verification script ('Verify.ps1') located in the _Installation_ folders -- or simply start using the available commands.

Should the above steps fail to work for you, please [let us know](https://github.com/pkjaer/tridion-powershell-modules/issues/new)! As an alternative to the installation script, follow the step-by-step instructions on the [Manual Installation](https://github.com/pkjaer/tridion-powershell-modules/wiki/Manual-Installation) page.

### Help

You can get the list of all of the commands by typing this in PowerShell: 
`Get-Command -Module Tridion-CoreService,Tridion-Alchemy`

Each of the commands also has help information available (including examples), which you can read by calling `Get-Help nameOfCommand` (e.g. `Get-Help Get-TridionUser`).


If you have any issues or questions, feel free to add an entry under [Issues](https://github.com/pkjaer/tridion-powershell-modules/issues).
