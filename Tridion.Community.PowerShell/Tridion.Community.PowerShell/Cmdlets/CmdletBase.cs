using CoreService;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    public class CmdletBase : PSCmdlet
    {
        protected static Regex _tcmUriRegex = new Regex("tcm:([0-9]+)-([0-9]+)(-([0-9]+))?(-v([0-9]+))?", RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.IgnorePatternWhitespace);

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

        protected bool IsTcmUri(string input)
        {
            return !string.IsNullOrWhiteSpace(input)
                ? _tcmUriRegex.IsMatch(input)
                : false;
        }

        protected bool IsNullUri(string id)
        {
            return string.IsNullOrWhiteSpace(id) || id.Trim().Equals("tcm:0-0-0", StringComparison.InvariantCultureIgnoreCase);
        }

        protected bool IsExistingItem(string id)
        {
            return AsyncHelper.RunSync(() => Client.Instance.IsExistingObjectAsync(id));
        }

        protected string GetIdFromParam(PSObject parameter)
        {
            return GetIdsFromParam(new[] { parameter })?.FirstOrDefault();
        }

        protected IEnumerable<string> GetIdsFromParam(PSObject[] parameter)
        {
            var result = new List<string>();
            result.AddRange(parameter.Select(p => p.BaseObject is string id ? id : (string)p.Properties["Id"]?.Value));
            return result;
        }

        protected T GetIdentifiableObjectFromParam<T>(PSObject parameter) where T : IdentifiableObjectData
        {
            return GetIdentifiableObjectsFromParam<T>(new[] { parameter })?.FirstOrDefault();
        }

        protected IEnumerable<T> GetIdentifiableObjectsFromParam<T>(PSObject[] parameter) where T : IdentifiableObjectData
        {
            var result = new List<T>();
            if (parameter == null) return result;

            foreach (var p in parameter)
            {
                if (p == null) continue;

                if (p.BaseObject is T obj)
                {
                    WriteDebug($"Parameter is of type {typeof(T).Name} -- reusing the object.");
                    result.Add(obj);
                }
                else if (p.BaseObject is string id)
                {
                    WriteDebug($"Parameter is a string -- loading the full item (ID = {id}).");
                    var item = AsyncHelper.RunSync(() => Client.Instance.ReadAsync(id, Client.DefaultReadOptions));
                    result.Add((T)item);
                }
                else
                {
                    WriteWarning($"Unexpected parameter type: {p.BaseObject.GetType().FullName}");
                }
            }

            return result;
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

        protected string GetSettingsPath()
        {
            string currentDir = CurrentProviderLocation("FileSystem")?.ProviderPath;
            if (string.IsNullOrWhiteSpace(currentDir)) return null;

            string directory = Path.Combine(currentDir, "Settings");
            return Path.Combine(directory, "CoreServiceSettings.xml");
        }
    }
}
