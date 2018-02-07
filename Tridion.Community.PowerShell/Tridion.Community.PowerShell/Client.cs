using CoreService;
using System;
using System.Net;
using System.Security.Principal;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Xml;

namespace Tridion.Community.PowerShell.CoreService
{
    public static class Client
    {
        private static SessionAwareCoreServiceClient _instance;
        private static readonly object _lock = new object();
        private static string _impersonateUserName;

        public static SessionAwareCoreServiceClient Instance
        {
            get
            {
                lock(_lock)
                {
                    // TODO: Check for faulted or closed state
                    return _instance ?? New(ImpersonateUserName);
                }
            }
            private set
            {
                lock(_lock)
                {
                    _instance = value;
                }
            }
        }

        public static string ImpersonateUserName
        {
            get
            {
                return _impersonateUserName;
            }
            set
            {
                if (_impersonateUserName != value)
                {
                    _impersonateUserName = value;
                    Invalidate();
                }
            }
        }

        public static void Invalidate()
        {
            Instance = null;
        }

        public static ReadOptions DefaultReadOptions
        {
            get
            {
                return new ReadOptions
                {
                    LoadFlags = LoadFlags.Expanded | LoadFlags.IncludeAllowedActions | LoadFlags.WebDavUrls
                };
            }
        }

        internal static SessionAwareCoreServiceClient New(string impersonateUserName)
        {
            return New(CoreServiceSettings.Instance, impersonateUserName);
        }

        internal static SessionAwareCoreServiceClient New(CoreServiceSettings settings, string impersonateUserName)
        {
            var binding = GetBinding(settings);
            var endpoint = new EndpointAddress(settings.EndpointUrl);
            var client = new SessionAwareCoreServiceClient(binding, endpoint);
            var networkCredential = settings.Credential?.GetNetworkCredential();

            if (settings.CredentialType == SupportedCredentialType.Basic)
            {
                if (networkCredential == null)
                {
                    throw new ArgumentException("Basic authentication has been specified but no credentials are available.");
                }

                client.ClientCredentials.UserName.UserName = GetFullUsername(networkCredential);
                client.ClientCredentials.UserName.Password = networkCredential.Password;

                //// TODO: When exactly is this needed? When connecting from Linux? Any external machine? Only when using Basic auth?
                //if (!(binding is NetTcpBinding))
                //{
                //    client.ClientCredentials.Windows.AllowedImpersonationLevel = TokenImpersonationLevel.Impersonation;
                //}
            }
            else
            {
                client.ClientCredentials.Windows.ClientCredential = networkCredential;
            }

            if (!string.IsNullOrWhiteSpace(impersonateUserName))
            {
                AsyncHelper.RunSync(() => client.ImpersonateAsync(impersonateUserName));
            }

            return client;
        }

        private static string GetFullUsername(NetworkCredential credential)
        {
            if (!string.IsNullOrWhiteSpace(credential.Domain))
		    {
				 return $"{credential.Domain}\\{credential.UserName}";
            }
            return credential.UserName;
        }

        private static Binding GetBinding(CoreServiceSettings settings)
        {
            if (settings.ConnectionType == SupportedConnectionType.NetTcp)
            {
                return GetNetTcpBinding(settings);
            }

            if (settings.ConnectionType == SupportedConnectionType.Basic)
            {
                return GetBasicHttpBinding(settings);
            }

            return GetWsHttpBinding(settings);
        }

        private static Binding GetNetTcpBinding(CoreServiceSettings settings)
        {
            // TODO? 
            // $binding.transactionFlow = $true; 
            // $binding.transactionProtocol = [ServiceModel.TransactionProtocol]::OleTransactions;
            var result = new NetTcpBinding
            {
                SendTimeout = settings.SendTimeout,
                MaxReceivedMessageSize = int.MaxValue,
                ReaderQuotas = new XmlDictionaryReaderQuotas
                {
                    MaxStringContentLength = int.MaxValue,
                    MaxArrayLength = int.MaxValue,
                    MaxBytesPerRead = int.MaxValue
                }
            };
            result.Security.Transport.ClientCredentialType = TcpClientCredentialType.Windows;
            return result;
        }

        private static Binding GetBasicHttpBinding(CoreServiceSettings settings)
        {
            var result = new BasicHttpBinding
            {
                SendTimeout = settings.SendTimeout,
                MaxReceivedMessageSize = int.MaxValue,
                ReaderQuotas = new XmlDictionaryReaderQuotas
                {
                    MaxStringContentLength = int.MaxValue,
                    MaxArrayLength = int.MaxValue,
                    MaxBytesPerRead = int.MaxValue
                }
            };

            result.Security.Mode =
                settings.UseSSL
                    ? BasicHttpSecurityMode.Transport
                    : BasicHttpSecurityMode.TransportCredentialOnly;

            result.Security.Transport.ClientCredentialType =
                (settings.CredentialType == SupportedCredentialType.Basic)
                    ? HttpClientCredentialType.Basic
                    : HttpClientCredentialType.Windows;

            return result;
        }

        private static Binding GetWsHttpBinding(CoreServiceSettings settings)
        {
            var result = new CustomBinding
            {
                SendTimeout = settings.SendTimeout
            };

            result.Elements.Add(
                new TextMessageEncodingBindingElement
                {
                    ReaderQuotas = new XmlDictionaryReaderQuotas
                    {
                        MaxStringContentLength = int.MaxValue,
                        MaxArrayLength = int.MaxValue,
                        MaxBytesPerRead = int.MaxValue
                    }
                }
            );

            result.Elements.Add(
                (settings.ConnectionType.ToString().Contains("SSL"))
                    ? new HttpsTransportBindingElement
                        {
                            AllowCookies = true,
                            MaxBufferSize = int.MaxValue,
                            MaxReceivedMessageSize = int.MaxValue
                        }
                    : new HttpTransportBindingElement
                        {
                            AllowCookies = true,
                            MaxBufferSize = int.MaxValue,
                            MaxReceivedMessageSize = int.MaxValue
                        }
            );

            return result;
        }
    }
}
