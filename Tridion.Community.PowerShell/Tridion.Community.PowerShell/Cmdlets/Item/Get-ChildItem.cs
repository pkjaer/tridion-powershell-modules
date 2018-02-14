using CoreService;
using System.Collections.Generic;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, Constants.CmdPrefix + "ChildItem")]
    [OutputType(typeof(List<IdentifiableObjectData>))]
    public class GetChildItemCommand : CmdletBase
    {
        protected delegate IEnumerable<IdentifiableObjectData> ChildRetriever(IdentifiableObjectData parent);

        [Parameter(Position= 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.GetChildItem.ParamParent)]
        [ValidateNotNullOrEmpty]
        public PSObject Parent { get; set; }

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = true, HelpMessage = Help.GetChildItem.ParamRecurse)]
        public SwitchParameter Recurse { get; set; }

        [Parameter(Position = 2, ValueFromPipelineByPropertyName = true, HelpMessage = Help.GetChildItem.ParamLevel)]
        public SwitchParameter Level { get; set; }

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = true, HelpMessage = Help.GetChildItem.ParamExpandProperties)]
        public virtual SwitchParameter ExpandProperties { get; set; }

        protected override void ProcessRecord()
        {
            var parent = GetIdentifiableObjectFromParam<IdentifiableObjectData>(Parent);
            WriteChildren(GetChildren(parent));
        }

        protected void WriteChildren(IEnumerable<IdentifiableObjectData> children, int level = 0)
        {
            foreach (var child in children)
            {
                var outputObject = new PSObject(ExpandPropertiesIfRequested(child));
                if (Level.IsPresent)
                {
                    var levelInfo = new PSNoteProperty("Level", level);
                    outputObject.Members.Add(levelInfo);
                }
                WriteObject(outputObject);

                if (Recurse.IsPresent)
                {
                    int nextLevel = level + 1;
                    WriteChildren(GetChildren(child, nextLevel), nextLevel);
                }
            }
        }

        private IdentifiableObjectData ExpandPropertiesIfRequested(IdentifiableObjectData item)
        {
            return ExpandProperties.IsPresent
                ? AsyncHelper.RunSync(() => Client.Instance.ReadAsync(item.Id, Client.DefaultReadOptions))
                : item;
        }

        protected IEnumerable<IdentifiableObjectData> GetChildren(IdentifiableObjectData parent, int level = 0)
        {
            if (parent == null)
            {
                return GetPublications();
            }

            if (parent is PublicationData publication)
            {
                return GetRootItems(publication);
            }

            if (parent is OrganizationalItemData org)
            {
                return GetChildItems(parent, level);
            }

            return new IdentifiableObjectData[] { };
        }

        protected IEnumerable<IdentifiableObjectData> GetPublications()
        {
            var filter = new PublicationsFilterData
            {
                BaseColumns = ListBaseColumns.Extended,
                IncludeAllowedActionsColumns = true,
                IncludeWebDavUrlColumn = true
            };

            WriteVerbose("Loading all Publications...");
            return AsyncHelper.RunSync(() => Client.Instance.GetSystemWideListAsync(filter));
        }

        private IEnumerable<IdentifiableObjectData> GetRootItems(PublicationData publication)
        {
            WriteVerbose($"Loading root items in Publication '{publication.Title}'...");

            var filter = new RepositoryItemsFilterData
            {
                BaseColumns = ListBaseColumns.Extended,
                IncludeAllowedActionsColumns = true,
                IncludeRelativeWebDavUrlColumn = true,
                Recursive = false,
                ShowNewItems = true
            };

            return AsyncHelper.RunSync(() => Client.Instance.GetListAsync(publication.Id, filter));
        }

        private IEnumerable<IdentifiableObjectData> GetChildItems(IdentifiableObjectData parent, int level)
        {
            var indentation = new string(' ', level);
            WriteVerbose($"{indentation}Loading child items in '{parent.Title}' ({parent.Id})...");

            SubjectRelatedListFilterData filter = new OrganizationalItemItemsFilterData
            {
                BaseColumns = ListBaseColumns.Extended,
                IncludeAllowedActionsColumns = true,
                IncludeRelativeWebDavUrlColumn = true,
                IncludePathColumn = true,
                Recursive = false,
                ShowNewItems = true
            };

            return AsyncHelper.RunSync(() => Client.Instance.GetListAsync(parent.Id, filter));
        }
    }
}
