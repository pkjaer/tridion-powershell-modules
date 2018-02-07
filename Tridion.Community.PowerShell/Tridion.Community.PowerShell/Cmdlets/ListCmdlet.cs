using CoreService;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    public abstract class ListCmdlet : CmdletBase
    {
        protected const string ParameterSetById = "ById";
        protected const string ParameterSetByName = "ByTitle";
        protected const string ParameterSetAll = "All";

        [Parameter(Position = 0, ValueFromPipelineByPropertyName = true, ParameterSetName = ParameterSetById, HelpMessage = Help.GetList.ParamId)]
        [ValidateNotNullOrEmpty]
        public string Id { get; set; }

        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, ParameterSetName = ParameterSetByName, HelpMessage = Help.GetList.ParamName)]
        [ValidateNotNullOrEmpty]
        [Alias("Title")]
        public string Name { get; set; }

        [Parameter(ParameterSetName = ParameterSetAll)]
        [Parameter(ParameterSetName = ParameterSetByName)]
        public virtual SwitchParameter ExpandProperties { get; set; }

        protected abstract int ExpectedItemType { get; }
        protected abstract string ItemTypeDescription { get; }
        protected abstract SystemWideListFilterData Filter { get; }

        protected override void ProcessRecord()
        {
            switch (ParameterSetName)
            {
                case ParameterSetById:
                    WriteObject(GetItemById());
                    break;
                case ParameterSetByName:
                    WriteAll(GetItemsByName());
                    break;
                default:
                    WriteAll(GetAllItems());
                    break;
            }
        }

        protected IdentifiableObjectData GetItemById()
        {
            if (IsNullUri(Id)) return null;
            AssertItemType(Id, ExpectedItemType);

            WriteVerbose($"Loading {ItemTypeDescription} with ID '{Id}'...");

            return IsExistingItem(Id)
                ? AsyncHelper.RunSync(() => Client.Instance.ReadAsync(Id, Client.DefaultReadOptions))
                : null;
        }

        protected IEnumerable<IdentifiableObjectData> GetItemsByName()
        {
            WriteVerbose($"Loading {ItemTypeDescription}(s) named '{Name}'...");

            var list = AsyncHelper.RunSync(() => Client.Instance.GetSystemWideListAsync(Filter));
            return ExpandPropertiesIfRequested(FilterByName(list));
        }

        protected IEnumerable<IdentifiableObjectData> GetAllItems()
        {
            WriteVerbose($"Loading all {ItemTypeDescription}s...");

            var list = AsyncHelper.RunSync(() => Client.Instance.GetSystemWideListAsync(Filter));
            return ExpandPropertiesIfRequested(list);
        }

        protected IEnumerable<IdentifiableObjectData> FilterByName(IEnumerable<IdentifiableObjectData> list)
        {
            return list.Where(p => Like(p.Title, Name));
        }

        protected IEnumerable<IdentifiableObjectData> ExpandPropertiesIfRequested(IEnumerable<IdentifiableObjectData> items)
        {
            foreach (var item in items)
            {
                yield return ExpandProperties
                    ? AsyncHelper.RunSync(() => Client.Instance.ReadAsync(item.Id, Client.DefaultReadOptions))
                    : item;
            }
        }
    }
}
