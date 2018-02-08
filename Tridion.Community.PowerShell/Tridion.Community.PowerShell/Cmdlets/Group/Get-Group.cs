using CoreService;
using System.Collections.Generic;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "Group", DefaultParameterSetName = ParameterSetAll)]
    [OutputType(typeof(IEnumerable<GroupData>), ParameterSetName = new[] { ParameterSetAll, ParameterSetByDescription, ParameterSetByName })]
    [OutputType(typeof(GroupData), ParameterSetName = new[] { ParameterSetById })]
    public class GetGroupCommand : ListCmdlet
    {
        protected const string ParameterSetByDescription = "ByDescription";

        // The "friendly" name of the Group to load. Wildcards are supported.
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "ByDescription")]
        [ValidateNotNullOrEmpty()]
        public string Description { get; set; }

		// Load all properties for each entry in the list. By default, only some properties are loaded (for performance reasons).
		[Parameter(ParameterSetName = ParameterSetByName)]
        [Parameter(ParameterSetName = ParameterSetByDescription)]
        [Parameter(ParameterSetName = ParameterSetAll)]
        public override SwitchParameter ExpandProperties { get; set; }

        protected override int ExpectedItemType => (int)ItemType.Group;

        protected override string ItemTypeDescription => "Group";

        protected override SystemWideListFilterData SystemWideListFilter => new GroupsFilterData();

        protected override void ProcessRecord()
        {
            switch(ParameterSetName)
            {
                case ParameterSetByDescription:
                    Filter = CreateLikeFilter("Description", Description);
                    base.ProcessRecord();
                    break;
                default:
                    base.ProcessRecord();
                    break;
            }
        }
    }
}
