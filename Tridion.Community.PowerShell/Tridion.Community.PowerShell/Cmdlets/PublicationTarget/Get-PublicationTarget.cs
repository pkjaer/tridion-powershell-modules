using System.Collections.Generic;
using System.Management.Automation;
using CoreService;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "PublicationTarget", DefaultParameterSetName = ParameterSetAll)]
    [OutputType(typeof(IEnumerable<PublicationTargetData>))]
    public class GetPublicationTargetCommand : ListCmdlet
    {
        protected override int ExpectedItemType => 65537;
        protected override string ItemTypeDescription => "Publication Target";

        protected override SystemWideListFilterData Filter => new PublicationTargetsFilterData();
    }
}
