using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.ServiceModel;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets.Settings
{
    [Cmdlet(VerbsDiagnostic.Test, Constants.CmdPrefix + "Settings", DefaultParameterSetName = ParameterSetVerify)]
    [OutputType(typeof(bool), ParameterSetName = new[] { ParameterSetVerify })]
    [OutputType(typeof(List<CoreServiceSettings>), ParameterSetName = new[] { ParameterSetAutoDetect })]
    [Alias(VerbsDiagnostic.Test + "-" + Constants.CmdPrefix + "CoreServiceSettings")]
    public class TestSettingsCommand : CmdletBase
    {
        protected const string ParameterSetAutoDetect = "AutoDetect";
        protected const string ParameterSetVerify = "Verify";

        [Parameter(Position = 0, Mandatory = true, ParameterSetName = ParameterSetAutoDetect)]
        public SwitchParameter AutoDetect { get; set; }

        [Parameter(Position = 1, ParameterSetName = ParameterSetAutoDetect)]
        [ValidateNotNullOrEmpty]
        public string HostName { get; set; }

        [Parameter(Position = 2, ParameterSetName = ParameterSetAutoDetect)]
        [Credential]
        public PSCredential Credential { get; set; }

        protected override void ProcessRecord()
        {
            if (AutoDetect.IsPresent)
            {
                AutoDetectSettings();
                return;
            }

            Verify();
        }

        private void Verify()
        {
            try
            {
                var version = AsyncHelper.RunSync(Client.Instance.GetApiVersionAsync);
                WriteObject(true);
            }
            catch
            {
                WriteObject(false);
            }
        }

        protected void AutoDetectSettings()
        {
            // TODO: Find a more optimal way to detect them. Currently bruteforcing every combination...
            var credentialTypes = Enum.GetValues(typeof(SupportedCredentialType)).Cast<SupportedCredentialType>();
            var connectionTypes = Enum.GetValues(typeof(SupportedConnectionType)).Cast<SupportedConnectionType>();
            var configurations = new List<CoreServiceSettings>();

            foreach(var connectionType in connectionTypes)
            {
                foreach(var credentialType in credentialTypes)
                {
                    configurations.Add(new CoreServiceSettings { ConnectionType = connectionType, CredentialType = credentialType });
                }
            }

            var result = new List<CoreServiceSettings>();

            foreach (var config in configurations)
            {
                config.HostName = HostName ?? config.HostName;
                config.Credential = Credential ?? config.Credential;

                if (Attempt(config))
                {
                    result.Add(config);
                }
            }

            if (result.Count > 0)
            {
                result.ForEach(c => WriteObject(c));
            }
            else
            {
                WriteWarning($"Auto detection of settings failed. Verify that the Core Service is running on {HostName ?? "localhost"} and that your firewall is not blocking the calls.");
            }
        }

        protected bool Attempt(CoreServiceSettings settings)
        {
            WriteVerbose($"Attempting with settings: {settings.EndpointUrl}, {settings.ConnectionType}, {settings.CredentialType}");
            if (settings.CredentialType == SupportedCredentialType.Basic && settings.Credential == null)
            {
                WriteWarning($"\tThe Credential parameter was omitted. Skipping this configuration ({settings.EndpointUrl}, {settings.ConnectionType}, {settings.CredentialType}).");
                return false;
            }

            var client = Client.New(settings, null);
            try
            {
                var apiVersion = AsyncHelper.RunSync(client.GetApiVersionAsync);
                WriteVerbose($"\tSuccess! API version: {apiVersion}");
                settings.Version = GetVersionSet(apiVersion);
                return true;
            }
            catch (ProtocolException ex)
            {
                WriteVerbose($"\tServer does not support this combination.");
                WriteDebug($"\tException: {ex}");
            }
            catch (CommunicationException ex)
            {
                if (ex.InnerException?.HResult == -2147012867)
                {
                    WriteVerbose("\tNo response.");
                    WriteDebug($"\tException: {ex}");
                }
                else
                {
                    WriteVerbose($"\tCommunication error: {ex.Message}");
                    WriteDebug($"\tException: {ex}");
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "AutoDetect", ErrorCategory.NotSpecified, this));
            }
            return false;
        }

        // TODO: Get rid of Version altogether? Or at least clean this up (SupportedTridionVersions enum?)
        protected string GetVersionSet(string apiVersion)
        {
            if (Version.TryParse(apiVersion, out var parsed))
            {
                if (parsed.Major == 9)
                {
                    return "9";
                }
                if (parsed.Major == 8)
                {
                    return parsed.Minor >= 5 ? "Web-8.5" : "Web-8.1";
                }

                if (parsed.Major == 7)
                {
                    return parsed.Minor >= 1 ? "2013-SP1" : "2013";
                }

                return "2011-SP1";
            }

            return null;
        }
    }
}
