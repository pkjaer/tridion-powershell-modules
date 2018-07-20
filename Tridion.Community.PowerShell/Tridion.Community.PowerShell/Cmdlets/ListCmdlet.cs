using CoreService;
using System.Collections.Generic;
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
        [SupportsWildcards]
        [Alias("Title")]
        public string Name { get; set; }

        // Filtering script block. You can use this to filter based on any criteria.
        [Parameter(Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = ParameterSetAll)]
        public ScriptBlock Filter { get; set; }

        [Parameter(ParameterSetName = ParameterSetAll)]
        [Parameter(ParameterSetName = ParameterSetByName)]
        public virtual SwitchParameter ExpandProperties { get; set; }

        protected abstract int ExpectedItemType { get; }
        protected abstract string ItemTypeDescription { get; }
        protected abstract SystemWideListFilterData SystemWideListFilter { get; }

        protected override void ProcessRecord()
        {
            switch (ParameterSetName)
            {
                case ParameterSetById:
                    WriteObject(GetItemById());
                    break;
                case ParameterSetByName:
                    WriteVerbose($"Loading {ItemTypeDescription}(s) named '{Name}'...");
                    Filter = CreateLikeFilter("Title", Name);
                    WriteAll(GetItems());
                    break;
                default:
                    WriteVerbose($"Loading all {ItemTypeDescription}s...");
                    WriteAll(GetItems());
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

        protected IEnumerable<IdentifiableObjectData> GetItems()
        {
            var list = AsyncHelper.RunSync(() => Client.Instance.GetSystemWideListAsync(SystemWideListFilter));
            // Applying the filter first would give better performance (fewer items to fully load)
            // But if the filter were based on properties that aren't returned by a list command, it wouldn't work.
            // Thus the filter is applied *after* expanding the properties.
            return ApplyFilter(ExpandPropertiesIfRequested(list));
        }

        protected ScriptBlock CreateLikeFilter(string propertyName, string value)
        {
            return ScriptBlock.Create($"{{ $_.{propertyName} -like '{value}'}}");
        }

        protected IEnumerable<IdentifiableObjectData> ApplyFilter(IEnumerable<IdentifiableObjectData> list)
        {
            if (Filter != null)
            {
                WriteVerbose("Filtering list...");
                return Where(list, Filter);
            }
            return list;
        }

        protected IEnumerable<T> Where<T>(IEnumerable<T> list, ScriptBlock filterExpr) where T : class
        {
            // This would normally be handled by a call to ScriptBlock.InvokeWithContext but it doesn't exist (yet?) in .NET Standard
            string filterScript = "$args[0] | Where-Object " + filterExpr.Ast;
            WriteDebug("Filtering using expression: " + filterScript);
            var filter = ScriptBlock.Create(filterScript);

            var result = new List<T>();
            foreach (var entry in filter.Invoke(list))
            {
                if (entry?.BaseObject is T outEntry)
                {
                    result.Add(outEntry);
                }
            }
            return result;
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
