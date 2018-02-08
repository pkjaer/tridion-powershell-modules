using CoreService;
using System.Collections.Generic;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.New, Constants.CmdPrefix + "Group")]
    [OutputType(typeof(GroupData))]
    public class NewGroupCommand : CmdletBase
    {
        protected readonly List<string> _memberOf = new List<string>();

        [Parameter(Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewGroup.ParamName)]
        [ValidateNotNullOrEmpty]
        [Alias("Title")]
        public string Name { get; set; }

        [Parameter(Position = 1, HelpMessage = Help.NewGroup.ParamDescription)]
        public string Description { get; set; }

        [Parameter(Position = 2, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewGroup.ParamMemberOf)]
        public PSObject[] MemberOf { get; set; }

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewGroup.ParamScope)]
        public string[] Scope { get; set; }

        protected override void ProcessRecord()
        {
            if (MemberOf != null)
            {
                _memberOf.AddRange(GetIdsFromParam(MemberOf));
            }
        }

        protected override void EndProcessing()
        {
            WriteVerbose($"Creating a new Group...");

            if (AsyncHelper.RunSync(() => Client.Instance.GetDefaultDataAsync(ItemType.Group, null)) is GroupData group)
            {
                group.Title = Name;
                group.Description = Description ?? Name;
                AddPublicationScopes(group);
                AddGroupMemberships(group);

                var result = AsyncHelper.RunSync(() => Client.Instance.SaveAsync(group, Client.DefaultReadOptions));
                WriteObject(result);
            }
        }

        private void AddPublicationScopes(GroupData group)
        {
            if (Scope != null)
            {
                group.Scope = GetLinks<LinkWithIsEditableToRepositoryData>(Scope);
            }
        }

        private void AddGroupMemberships(GroupData group)
        {
            if (_memberOf.Count < 1) return;

            var memberships = new List<GroupMembershipData>();
            foreach(var uri in _memberOf)
            {
                memberships.Add(new GroupMembershipData
                {
                    Group = new LinkToGroupData { IdRef = uri }
                });
            }

            group.GroupMemberships = memberships.ToArray();
        }
    }
}
