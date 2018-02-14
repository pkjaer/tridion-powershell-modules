using CoreService;
using System.Collections.Generic;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    public abstract class NewTrusteeCmdlet : CmdletBase
    {
        private readonly TitleCache _groupTitleCache;
        protected readonly List<string> _memberOf = new List<string>();

        public abstract PSObject[] MemberOf { get; set; }

        protected NewTrusteeCmdlet()
        {
            _groupTitleCache = new TitleCache(LoadGroups);
        }

        protected override void ProcessRecord()
        {
            if (MemberOf != null)
            {
                _memberOf.AddRange(GetIdsFromParam(MemberOf));
            }
        }

        protected void AddGroupMemberships(TrusteeData group)
        {
            if (_memberOf.Count < 1) return;

            var memberships = new List<GroupMembershipData>();
            foreach (var identifier in _memberOf)
            {
                string groupUri = identifier;

                if (!IsTcmUri(identifier))
                {
                    WriteDebug($"Looking up title: {identifier}");
                    groupUri = _groupTitleCache.Lookup(identifier);
                    WriteDebug($"{identifier} => {groupUri}");
                }

                memberships.Add(new GroupMembershipData
                {
                    Group = new LinkToGroupData { IdRef = groupUri }
                });
            }

            group.GroupMemberships = memberships.ToArray();
        }

        private Dictionary<string, string> LoadGroups()
        {
            WriteVerbose("Loading list of groups, in order to look up by name...");

            var groups = AsyncHelper.RunSync(() => Client.Instance.GetSystemWideListAsync(new GroupsFilterData()));
            var result = new Dictionary<string, string>();

            foreach (var group in groups)
            {
                result.Add(group.Title, group.Id);
            }

            WriteVerbose($"Loaded {result.Count} groups.");
            return result;
        }
    }
}
