using CoreService;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    public class CmdletBase : PSCmdlet
    {
        protected bool IsPresent(string parameterName)
        {
            return MyInvocation.BoundParameters.ContainsKey(parameterName);
        }

        protected int GetItemType(string id)
        {
            if (!string.IsNullOrWhiteSpace(id))
            {
                var parts = id.Split('-');
                switch(parts.Length)
                {
                    case 2:
                        return 16;
                    case 3:
                    case 4:
                        return int.Parse(parts[2]);
                }
            }
            return 0;
        }

        protected void AssertItemType(string id, int expectedItemType)
        {
            int itemType = GetItemType(id);
            if (itemType != expectedItemType)
            {
                throw new ArgumentException($"Unexpected item type '{itemType}'. Expected '{expectedItemType}'.");
            }
        }

        protected bool IsNullUri(string id)
        {
            return string.IsNullOrWhiteSpace(id) || id.Trim().Equals("tcm:0-0-0", StringComparison.InvariantCultureIgnoreCase);
        }

        protected bool IsExistingItem(string id)
        {
            return AsyncHelper.RunSync(() => Client.Instance.IsExistingObjectAsync(id));
        }

        protected T[] GetLinks<T>(IEnumerable<string> ids) where T : Link, new()
        {
            if (ids == null) return new T[] { };

            var result = new List<T>();
            foreach (var id in ids.Where(p => !IsNullUri(p)))
            {
                result.Add(new T { IdRef = id });
            }
            return result.ToArray();
        }

        protected void WriteAll(IEnumerable<object> sendToPipeline)
        {
            if (sendToPipeline == null) return;

            foreach (var obj in sendToPipeline)
            {
                WriteObject(obj);
            }
        }
    }
}
