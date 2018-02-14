using System;
using System.Collections.Generic;

namespace Tridion.Community.PowerShell.CoreService
{
    internal class TitleCache
    {
        public delegate Dictionary<string, string> ListLoader();
        protected ListLoader _loader;

        protected Lazy<Dictionary<string, string>> _uriLookup;

        public TitleCache(ListLoader loader)
        {
            _loader = loader ?? throw new ArgumentNullException(nameof(loader));
            _uriLookup = new Lazy<Dictionary<string, string>>(() => _loader());
        }

        public string Lookup(string title)
        {
            return _uriLookup.Value.TryGetValue(title, out string result) ? result : null;
        }
    }
}
