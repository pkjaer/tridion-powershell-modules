using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "Settings")]
    [OutputType(typeof(CoreServiceSettings))]
    [Alias(VerbsCommon.Get + "-" + Constants.CmdPrefix + "CoreServiceSettings")]
    public class GetSettingsCommand : CmdletBase
    {
        protected override void ProcessRecord()
        {
            WriteObject(CoreServiceSettings.Instance);
        }
    }
}
