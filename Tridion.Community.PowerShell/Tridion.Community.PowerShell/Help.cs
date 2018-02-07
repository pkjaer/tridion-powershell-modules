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

        internal static class GetList
        {
            public const string ParamId = "The TCM URI or WebDAV URL of the item to retrieve.";
            public const string ParamName = "The name of the item(s) to load. This is slower than specifying the ID.";
        }
    }
}
