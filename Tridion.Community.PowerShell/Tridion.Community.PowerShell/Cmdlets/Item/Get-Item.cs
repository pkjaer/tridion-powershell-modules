using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "Item")]
    [OutputType(typeof(global::CoreService.IdentifiableObjectData))]
    public class GetItemCommand : CmdletBase
    {
        [Parameter(Position= 0, Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.GetItem.ParamId)]
        [ValidateNotNullOrEmpty]
        public string Id { get; set; }

        protected override void ProcessRecord()
        {
            WriteVerbose($"Loading item with ID '{Id}'...");
            WriteObject(AsyncHelper.RunSync(() => Client.Instance.ReadAsync(Id, Client.DefaultReadOptions)));
        }
    }
}
