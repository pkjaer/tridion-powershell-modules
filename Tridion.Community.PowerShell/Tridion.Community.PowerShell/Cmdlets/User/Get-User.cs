using CoreService;
using System.Collections.Generic;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "User", DefaultParameterSetName = ParameterSetAll)]
    [OutputType(typeof(IEnumerable<UserData>), ParameterSetName = new[] { ParameterSetAll, ParameterSetByDescription, ParameterSetByName })]
    [OutputType(typeof(UserData), ParameterSetName = new[] { ParameterSetCurrentUser, ParameterSetById })]
    public class GetUserCommand : ListCmdlet
    {
        protected const string ParameterSetByDescription = "ByDescription";
        protected const string ParameterSetCurrentUser = "CurrentUser";

        // The "friendly" name of the user to load. Wildcards are supported.
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "ByDescription")]
        [ValidateNotNullOrEmpty()]
        public string Description { get; set; }

		// Only return the currently logged on user.
        [Parameter(Position = 0, Mandatory = true, ParameterSetName = ParameterSetCurrentUser)]
        public SwitchParameter Current { get; set; }

		// Load all properties for each entry in the list. By default, only some properties are loaded (for performance reasons).
		[Parameter(ParameterSetName = ParameterSetByName)]
        [Parameter(ParameterSetName = ParameterSetByDescription)]
        [Parameter(ParameterSetName = ParameterSetAll)]
        public override SwitchParameter ExpandProperties { get; set; }

        protected override int ExpectedItemType => (int)ItemType.User;

        protected override string ItemTypeDescription => "User";

        protected override SystemWideListFilterData SystemWideListFilter => new UsersFilterData { IsPredefined = false };

        protected override void ProcessRecord()
        {
            switch(ParameterSetName)
            {
                case ParameterSetByDescription:
                    Filter = CreateLikeFilter("Description", Description);
                    base.ProcessRecord();
                    break;
                case ParameterSetCurrentUser:
                    WriteVerbose("Loading current user...");
                    WriteObject(AsyncHelper.RunSync(Client.Instance.GetCurrentUserAsync));
                    break;
                default:
                    base.ProcessRecord();
                    break;
            }
        }
    }
}
