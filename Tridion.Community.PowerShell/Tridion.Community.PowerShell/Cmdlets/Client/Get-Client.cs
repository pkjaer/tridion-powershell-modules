using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "Client")]
    [OutputType(typeof(global::CoreService.ISessionAwareCoreService))]
    [Alias(VerbsCommon.Get + "-" + Constants.CmdPrefix + "CoreServiceClient")]
    public class GetCoreServiceClientCommand : CmdletBase
    {
        [Parameter(Position = 0, HelpMessage = Help.GetClient.ParamImpersonateUserName)]
        public string ImpersonateUserName { get; set; }

        protected override void ProcessRecord()
        {
            var serviceInfo = CoreServiceSettings.Instance;
            WriteVerbose($"Connecting to the Core Service at {serviceInfo.HostName}...");
            WriteObject(Client.New(ImpersonateUserName));
        }
    }
}
