### Tridion-Alchemy module

This module contains cmdlets that allow you to manage [Alchemy](http://www.alchemywebstore.com) plugins for your Tridion Content Manager.
Install, uninstall, or updating plugins directly from PowerShell. Or let the Plugin Monitor cmdlet do it for you whenever your plugin changes.


### Installation
[Click here to view the installation instructions](https://github.com/pkjaer/tridion-powershell-modules/), which cover installation of all of the modules.


### Release notes

v1.0.0.0

- Initial version of the module.
- Supports getting a list of installed plugins (Get-AlchemyPlugins)
- Supports installation and uninstallation (Install-AlchemyPlugin, Uninstall-AlchemyPlugin, Update-AlchemyPlugin)
- Supports connecting to a local or remote Tridion Content Manager instance (Set-AlchemyConnectionSettings, Get-AlchemyConnectionSettings)
- Supports monitoring a folder for plugin file changes (.a4t) and automatically uploading the new version(s) (Start-AlchemyPluginMonitor, Stop-AlchemyPluginMonitor)
- Supports extracting the plugin name from a plugin file (.a4t). Useful for commands that work on the plugin name, as opposed to the file itself.
