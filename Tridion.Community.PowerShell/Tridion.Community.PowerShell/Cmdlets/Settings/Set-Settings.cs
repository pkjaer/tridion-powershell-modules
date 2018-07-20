using System;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Set, Constants.CmdPrefix + "Settings")]
    [Alias(VerbsCommon.Set + "-" + Constants.CmdPrefix + "CoreServiceSettings")]
    public class SetSettingsCommand : CmdletBase
    {
        [Parameter]
        [ValidateNotNullOrEmpty]
        public string HostName { get; set; }

        [Parameter]
        [Credential]
        public PSCredential Credential { get; set; }

        [Parameter]
        public string SendTimeout { get; set; }

        [Parameter]
        [ValidateSet("", "2011-SP1", "2013", "2013-SP1", "Web-8.1", "Web-8.5")]
        public string Version { get; set; }

        [Parameter]
        public SupportedCredentialType CredentialType { get; set; }

        [Parameter]
        public SupportedConnectionType ConnectionType { get; set; }

        [Parameter]
        public SwitchParameter UseSSL { get; set; }

        [Parameter]
        public SwitchParameter Persist { get; set; }

        [Parameter]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            var settings = new CoreServiceSettings();

            if (IsPresent(nameof(HostName)))
                settings.HostName = HostName;
            if (IsPresent(nameof(Version)))
                settings.Version = Version;
            if (IsPresent(nameof(Credential)))
                settings.Credential = Credential;
            if (IsPresent(nameof(CredentialType)))
                settings.CredentialType = CredentialType;
            if (IsPresent(nameof(ConnectionType)))
                settings.ConnectionType = ConnectionType;
            if (IsPresent(nameof(SendTimeout)))
                settings.SendTimeout = TimeSpan.Parse(SendTimeout);

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
