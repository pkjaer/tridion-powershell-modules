namespace Tridion.Community.PowerShell.CoreService
{
    internal static class Help
    {
        internal static class GetItem
        {
            public const string ParamId = "The TCM URI or WebDAV URL of the item to retrieve.";
        }

        internal static class NewItem
        {
            public const string ParamItemType = "The item type of the new item.";
            public const string ParamName = "The title of the new item.";
            public const string ParamParent = "ID of the organizational item that will hold the new item.";
        }

        internal static class RemoveItem
        {
            public const string ParamId = "The TCM URI or WebDAV URL of the item to delete.";
        }

        internal static class TestItem
        {
            public const string ParamId = "The TCM URI or WebDAV URL of the item you wish to know exists.";
        }

        internal static class GetClient
        {
            public const string ParamImpersonateUserName = @"The name (including domain) of the user to impersonate when accessing Tridion. 
When omitted the current user will be executing all Tridion commands.
";
        }

        internal static class GetPublication
        {
            public const string ParamPublicationType = @"The type of Publications to include in the list. 
Examples include 'Web', 'Content', and 'Mobile'. Omit to retrieve all Publications.";
        }

        internal static class NewPublication
        {
            public const string ParamName = "The title of the new Publication.";
            public const string ParamParent = "The Publication(s) you wish to make this Publication a child of. Accepts multiple values as an array.";
        }

        internal static class NewGroup
        {
            public const string ParamName = "The name of the new Group. This is displayed to end-users.";
            public const string ParamDescription = "The description of the new Group. Generally used to indicate the purpose of the group.";
            public const string ParamScope = "A list of URIs for the Publications in which the new Group applies.";
            public const string ParamMemberOf = "A list of URIs for the existing Groups that the new Group should be a part of.";
        }

        internal static class NewUser
        {
            public const string ParamName = "The username (including domain) of the new User";
            public const string ParamDescription = "The description (or 'friendly name') of the user. This is displayed throughout the UI.";
            public const string ParamMemberOf = "A list of URIs for the existing Groups that the new User should be a part of. Supports also Titles of the groups.";
            public const string ParamMakeAdministrator = "If set, the new user will have system administrator privileges. Use with caution.";
        }

        internal static class GetList
        {
            public const string ParamId = "The TCM URI or WebDAV URL of the item to retrieve.";
            public const string ParamName = "The name of the item(s) to load. This is slower than specifying the ID.";
        }
    }
}
