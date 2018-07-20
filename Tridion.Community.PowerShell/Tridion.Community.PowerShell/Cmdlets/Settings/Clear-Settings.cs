using System;
using System.IO;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Clear, Constants.CmdPrefix + "Settings")]
    [OutputType(typeof(CoreServiceSettings))]
    [Alias(VerbsCommon.Clear + "-" + Constants.CmdPrefix + "CoreServiceSettings")]
    public class ClearSettingsCommand : CmdletBase
    {
        [Parameter]
        public SwitchParameter Persist { get; set; }

        [Parameter]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            var settings = new CoreServiceSettings();

            if (Persist.IsPresent)
            {
                string path = GetSettingsPath();
                if (!settings.Save(path))
                {
                    WriteWarning($"Failed to save your settings for next time. Perhaps you do not have permissions to modify '{path}'?");
                }
            }

            CoreServiceSettings.Instance = settings;
            Client.Invalidate();

            if (PassThru.IsPresent)
            {
                WriteObject(settings);
            }
        }
    }
}
