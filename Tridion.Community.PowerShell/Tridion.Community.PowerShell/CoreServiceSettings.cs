using System;
using System.Management.Automation;
using System.Reflection;

namespace Tridion.Community.PowerShell.CoreService
{
    public class CoreServiceSettings
    {
        // Private members
        protected static CoreServiceSettings _instance;
        protected static object _instanceLock = new object();

        // Public members
        public string HostName { get; set; }
        public TimeSpan SendTimeout { get; set; }
        public PSCredential Credential { get; set; }
        public string Version { get; set; } // Deprecated?
        public Version ModuleVersion { get; set; }
        public SupportedConnectionType ConnectionType { get; set; }
        public SupportedCredentialType CredentialType { get; set; }
        public bool UseSSL { get; set; }

        // Internal?
        public string EndpointUrl
        {
            get
            {
                // TODO: Base URL on Version
                // TODO: Simplify this to a few new properties? Protocol, Port?
                bool netTcp = ConnectionType == SupportedConnectionType.NetTcp || ConnectionType == SupportedConnectionType.Default;
                bool basic = ConnectionType == SupportedConnectionType.Basic;
                string protocol = UseSSL ? "https://" : netTcp ? "net.tcp://" : "http://";
                string port = netTcp ? ":2660" : "";

                var relativeUrl = netTcp
                    ? "/CoreService/2011/netTcp"
                    : basic
                        ? "/webservices/CoreService2011.svc/basicHttp"
                        : "/webservices/CoreService2011.svc/wsHttp";

                return string.Concat(protocol, HostName, port, relativeUrl);
            }
        }

        public static CoreServiceSettings Instance
        {
            get
            {
                lock(_instanceLock)
                {
                    // TODO: Load from persistant storage
                    return _instance ?? new CoreServiceSettings();
                }
            }
            set
            {
                lock(_instanceLock)
                {
                    _instance = value ?? throw new ArgumentNullException(nameof(Instance));
                }
            }
        }

        public CoreServiceSettings()
        {
            HostName = "localhost";
            SendTimeout = new TimeSpan(0, 1, 0);
            Version = "2011-SP1";
            ModuleVersion = Assembly.GetExecutingAssembly().GetName().Version;
            ConnectionType = SupportedConnectionType.Default;
            CredentialType = SupportedCredentialType.Default;
        }
    }
}
