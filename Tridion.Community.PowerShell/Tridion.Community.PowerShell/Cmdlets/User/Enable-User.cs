using CoreService;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsLifecycle.Enable, Constants.CmdPrefix + "User")]
    [OutputType(typeof(UserData))]
    public class EnableUserCommand : CmdletBase
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.EnableUser.ParamUser)]
        [Alias("Id")]
        public PSObject User { get; set; }

        [Parameter(Position = 1, HelpMessage = Help.EnableUser.ParamPassThru)]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            var user = GetIdentifiableObjectFromParam<UserData>(User );
            if (user == null) return;

            user.IsEnabled = true;
            user = (UserData)AsyncHelper.RunSync(() => Client.Instance.SaveAsync(user, Client.DefaultReadOptions));

            if (PassThru.IsPresent)
            {
                WriteObject(user);
            }
        }
    }
}
