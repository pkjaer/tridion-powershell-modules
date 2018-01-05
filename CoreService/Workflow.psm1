#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>
. (Join-Path $PSScriptRoot 'Utilities.ps1')

function _GetProcessFilter($ProcessType)
{
	$filter = New-Object Tridion.ContentManager.CoreService.Client.ProcessesFilterData;
	$filter.ProcessType = $ProcessType;
	return $filter;
}

function _FilterByAssignee($Client, $Items, $AssignedTo)
{
	if ($Items -eq $null) { return $null; }
	$result = @();

	foreach ($item in $Items)
	{
		$processInstance = _GetItem $Client $item.Id;

		# When looking at finished processes, we should search through all activities ("it was once assigned to X").
		# For active ones, we only care who about the current assignee.
		$isProcessHistory = _IsObjectType $processInstance 'ProcessHistoryData';
		$activities = $processInstance.Activities;
		if (!$isProcessHistory)
		{
			$activities = $activities | Select-Object -Last 1;
		}
		
		foreach ($activity in $activities)
		{
			$assignee = $activity.Assignee.Title;
			if (_IsTcmUri $AssignedTo)
			{
				$assignee = $activity.Assignee.IdRef;
			}

			if ($assignee -like $AssignedTo)
			{
				$result += $processInstance;
				break;
			}
		}
	}

	return $result;
}

<#
**************************************************
* Public members
**************************************************
#>

function Get-TridionWorkflowItem
{
    <#
    .Synopsis
    Gets a list of workflow items from Tridion Content Manager.
	
    .Description
    Gets a list of workflow items from Tridion Content Manager, optionally filtered by status or assigned trustee.
	
    .Notes
    Example of properties available: Id, Title, Etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.ProcessInstanceData object)
	
    .Inputs
	None.

    .Outputs
	Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.ProcessInstanceData] 
	or [Tridion.ContentManager.CoreService.Client.ProcessHistoryData].
	
    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
    .Example
    Get-TridionWorkflowItem
	Returns a list of all workflow items (both active and historical).
	
	.Example
    Get-TridionWorkflowItem -Status Active
	Returns a list of all currently active workflow items.
	
	.Example
	Get-TridionWorkflowItem -Status Historical
	Returns a list of all historical (archived) workflow items.
	
	.Example
	Get-TridionWorkflowItem -AssignedTo 'tcm:0-12-65552'
	Returns a list of all workflow items (past and present) assigned to the user with ID 'tcm:0-12-65552'.

	.Example
	Get-TridionWorkflowItem -AssignedTo 'tcm:0-7-65568'
	Returns a list of all workflow items (past and present) assigned to the group with ID 'tcm:0-7-65568'.

	.Example
	Get-TridionWorkflowItem -AssignedTo 'DOMAIN\Isaac'
	Returns a list of all workflow items (past and present) assigned to the user with username 'DOMAIN\Isaac'.

	.Example
	Get-TridionWorkflowItem -AssignedTo 'Editor'
	Returns a list of all workflow items (past and present) assigned to the 'Editor' group.

	.Example
	Get-TridionWorkflowItem -AssignedTo 'Editor' -Status Active
	Returns a list of all active workflow items assigned to the 'Editor' group.
	
	.Example
	Get-TridionWorkflowItem -AssignedTo 'Editor' | Select-Object Id, Title
	Returns a list of the ID and Title of all workflow items (past and present) assigned to the 'Editor' group.
	
	.Example
	Get-TridionWorkflowItem -Status 'Active' | Select-Object Id, Title
	Returns a list of the ID and Title of all currently active workflow items.

	.Example
	Get-TridionUser -Current | Get-TridionWorkflowItem
	Returns a list of all workflow items (past and present) assigned to you.

	.Example
	Get-TridionWorkflowItem -AssignedTo 'SDL Web*'
	Returns a list of all workflow items (past and present) assigned to any group whose name begins with 'SDL Web'

	.Example
	Get-TridionWorkflowItem -AssignedTo 'DOMAIN\*'
	Returns a list of all workflow items (past and present) assigned to any user in the 'DOMAIN' domain.
    #>
    [CmdletBinding(DefaultParameterSetName='Status')]
    Param
    (
		# Filter by assignee. This can be a TCM URI or a (partial) title of a user or group. Including this parameter makes it slower, due to more data being loaded.
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Alias('Id')]
		[string]$AssignedTo,
		
		# Filter by the status of the workflow process. Historical refers to processes that have been finished.
		[ValidateSet('Any', 'Active', 'Historical')]
		[string]$Status = 'Any',

		# Load all properties for each entry in the list. By default, only some properties are loaded (for performance reasons).
		[switch]$ExpandProperties
	)
	
	Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Loading list of workflow items with status '$Status'...";

			$filter = _GetProcessFilter $Status;
			$list = _GetSystemWideList $client $filter;

			if ($AssignedTo)
			{
				Write-Verbose "Filtering the list to only include items assigned to '$AssignedTo'...";
				$list = _FilterByAssignee $client $list $AssignedTo;

				# _FilterByAssignee already expanded the properties (to determine the assignee)
				$ExpandProperties = $false;
			}

			return _ExpandPropertiesIfRequested $list $ExpandProperties;
        }
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}