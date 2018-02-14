using CoreService;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsLifecycle.Disable, Constants.CmdPrefix + "User")]
    [OutputType(typeof(UserData))]
    public class DisableUserCommand : CmdletBase
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.DisableUser.ParamUser)]
        [Alias("Id")]
        public PSObject User { get; set; }

        [Parameter(Position = 1, HelpMessage = Help.DisableUser.ParamPassThru)]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            var user = GetIdentifiableObjectFromParam<UserData>(User );
            if (user == null) return;

            user.IsEnabled = false;
            user = (UserData)AsyncHelper.RunSync(() => Client.Instance.SaveAsync(user, Client.DefaultReadOptions));

            if (PassThru.IsPresent)
            {
                WriteObject(user);
            }
        }
    }
}
