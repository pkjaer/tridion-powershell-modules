using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsDiagnostic.Test, Constants.CmdPrefix + "Item")]
    public class TestItemCommand : CmdletBase
    {
        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.TestItem.ParamId)]
        [Alias("Item")]
        [ValidateNotNullOrEmpty]
        public string Id { get; set; }

        protected override void ProcessRecord()
        {
            WriteVerbose($"Checking if item with ID '{Id}' exists...");
            WriteObject(IsExistingItem(Id));
        }
    }
}
