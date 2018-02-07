using System;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "ApiVersion")]
    [OutputType(typeof(Version))]
    public class GetApiVersionCommand : CmdletBase
    {
        protected override void ProcessRecord()
        {
            var versionString = AsyncHelper.RunSync(Client.Instance.GetApiVersionAsync);
            if (string.IsNullOrWhiteSpace(versionString)) return;

            if (Version.TryParse(versionString, out var parsed))
            {
                // Fix for Revision -1
                WriteObject(new Version(parsed.Major, parsed.Minor, parsed.Build, Math.Max(parsed.Revision, 0)));
            }
        }
    }
}
