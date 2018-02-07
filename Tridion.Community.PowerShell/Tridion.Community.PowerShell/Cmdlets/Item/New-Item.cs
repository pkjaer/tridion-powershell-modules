using CoreService;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.New, Constants.CmdPrefix + "Item")]
    [OutputType(typeof(IdentifiableObjectData))]
    public class NewItemCommand : CmdletBase
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewItem.ParamItemType)]
        public ItemType ItemType { get; set; }

        [Parameter(Position = 1, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewItem.ParamName)]
        [ValidateNotNullOrEmpty]
        [Alias("Title")]
        public string Name { get; set; }

        [Parameter(Position = 2, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewItem.ParamParent)]
        [ValidateNotNullOrEmpty]
        [Alias("Id")]
        public string Parent { get; set; }

        protected override void ProcessRecord()
        {
            WriteVerbose($"Creating a new {ItemType}...");

            var item = AsyncHelper.RunSync(() => Client.Instance.GetDefaultDataAsync(ItemType, Parent));
            if (item != null)
            {
                item.Title = Name;
                var result = AsyncHelper.RunSync(() => Client.Instance.SaveAsync(item, Client.DefaultReadOptions));
                WriteObject(result);
            }
        }
    }
}
