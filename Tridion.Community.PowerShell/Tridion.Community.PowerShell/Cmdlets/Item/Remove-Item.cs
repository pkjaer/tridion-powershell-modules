using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Remove, Constants.CmdPrefix + "Item")]
    public class RemoveItemCommand : CmdletBase
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.RemoveItem.ParamId)]
        [Alias("Item")]
        [ValidateNotNullOrEmpty]
        public string Id { get; set; }

        protected override void ProcessRecord()
        {
            if (IsExistingItem(Id))
            {
                WriteVerbose($"Deleting item with ID '{Id}'...");
                AsyncHelper.RunSync(() => Client.Instance.DeleteAsync(Id));
            }
        }
    }
}
