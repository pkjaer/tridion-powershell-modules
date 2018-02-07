using System.Collections.Generic;
using System.Management.Automation;
using CoreService;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "Publication", DefaultParameterSetName = ParameterSetAll)]
    [OutputType(typeof(IEnumerable<PublicationData>))]
    public class GetPublicationCommand : ListCmdlet
    {
        private const string ParameterSetByPublicationType = "ByPublicationType";

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = true,
            ParameterSetName = ParameterSetByPublicationType,
            HelpMessage = Help.GetPublication.ParamPublicationType)]
        public string PublicationType { get; set; }

        [Parameter(ParameterSetName = ParameterSetAll, Position = 2)]
        [Parameter(ParameterSetName = ParameterSetByName, Position = 2)]
        [Parameter(ParameterSetName = ParameterSetByPublicationType, Position = 2)]
        public override SwitchParameter ExpandProperties { get; set; }

        protected override int ExpectedItemType => 1;
        protected override string ItemTypeDescription => "Publication";

        protected override SystemWideListFilterData Filter => new PublicationsFilterData { PublicationTypeName = PublicationType };
    }
}
