using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using CoreService;

namespace Tridion.Community.PowerShell.CoreService.Cmdlets
{
    [Cmdlet(VerbsCommon.New, Constants.CmdPrefix + "Publication")]
    [OutputType(typeof(PublicationData))]
    public class NewPublicationCommand : CmdletBase
    {
        private readonly List<string> _parents = new List<string>();

        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewPublication.ParamName)]
        [ValidateNotNullOrEmpty]
        [Alias("Title")]
        public string Name { get; set; }

        [Parameter(ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, HelpMessage = Help.NewPublication.ParamParent)]
        [ValidateNotNullOrEmpty]
        [Alias("Parents")]
        public string[] Parent { get; set; }

        protected override void ProcessRecord()
        {
            _parents.AddRange(Parent);
        }

        protected override void EndProcessing()
        {
            var publication = AsyncHelper.RunSync(() => Client.Instance.GetDefaultDataAsync(ItemType.Publication, null)) as PublicationData;
            if (publication == null) throw new System.Exception("Unable to create Publication.");
            publication.Title = Name;
            publication.Parents = GetLinks<LinkToRepositoryData>(_parents);

            var result = AsyncHelper.RunSync(() => Client.Instance.SaveAsync(publication, Client.DefaultReadOptions));
            WriteObject(result);
        }
    }
}
