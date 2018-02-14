using CoreService;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.New, Constants.CmdPrefix + "User")]
    [OutputType(typeof(UserData))]
    public class NewUserCommand : NewTrusteeCmdlet
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewUser.ParamName)]
        [ValidateNotNullOrEmpty]
        [Alias("Title")]
        public string Name { get; set; }

        [Parameter(Position = 1, HelpMessage = Help.NewUser.ParamDescription)]
        public string Description { get; set; }

        [Parameter(Position = 2, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewUser.ParamMemberOf)]
        public override PSObject[] MemberOf { get; set; }

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewUser.ParamMakeAdministrator)]
        public SwitchParameter MakeAdministrator { get; set; }

        protected override void EndProcessing()
        {
            WriteVerbose($"Creating a new User...");

            if (AsyncHelper.RunSync(() => Client.Instance.GetDefaultDataAsync(ItemType.User, null)) is UserData user)
            {
                user.Title = Name;
                user.Description = Description ?? Name;
                AddGroupMemberships(user);

                if (MakeAdministrator.IsPresent)
                {
                    user.Privileges = 1;
                }

                var result = AsyncHelper.RunSync(() => Client.Instance.SaveAsync(user, Client.DefaultReadOptions));
                WriteObject(result);
            }
        }
    }
}
