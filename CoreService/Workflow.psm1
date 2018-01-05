#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>
. (Join-Path $PSScriptRoot 'Utilities.ps1')


<#
**************************************************
* Public members
**************************************************
#>

function Get-TridionWorkflowItem
{
    <#
    .Synopsis
    Get list of Workflow Items from Tridion Content Manager By Status or AssignedTo Filter
	
    .Description
    Get list of Workflow Items from Tridion Content Manager By Status or AssignedTo Filter
	
    .Notes
    Example of properties available: Id, Title Etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.ProcessInstanceData object)
	
    .Inputs
     [string] Status(Not Mandetory): Workflow ProcessInstanceData by status "Active" or "Historical" (By default it will show all the data)
	 [string] AssignedTo: The processInstanceData assigned to the given ID/Title of User or Group. (For User Title provide : <domainname>\<username>)
	
    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.ProcessInstanceData].
	
    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
    .Example
    Get-TridionWorkflowItems
	Returns a list of all workflow items within Tridion (Active and Historical).
	
	.Example
    Get-TridionWorkflowItem -Status "Active"
	Returns a list of all workflow items within Tridion filtered By Status(Active) of The Workflow.
	
	.Example
	Get-TridionWorkflowItem -Status "Historical"
	Returns a list of all workflow items within Tridion filtered By Status(Historical) of The Workflow.
	
	.Example
    Get-TridionWorkflowItem -AssignedTo "tcm:0-1014-65552"
	Get-TridionWorkflowItem -AssignedTo "tcm:0-15-65568"
	Get-TridionWorkflowItem -AssignedTo "TRIDIONDEV\San"
	Get-TridionWorkflowItem -AssignedTo "Developer"
	Returns a list of all workflow items within Tridion filtered by AssignedTo given ID/Title of User or Group.
	
	.Example
    Get-TridionWorkflowItem -Status "Active" | Select-Object Title, Id
	Get-TridionWorkflowItem -AssignedTo "tcm:0-1014-65552" | Select-Object Id,Title
	Returns a list of the Title, Id of all workflow items within Tridion filtered By Status(Active) or AssignedTo filter of The Workflow.
    #>
    [CmdletBinding(DefaultParameterSetName='Status')]
    Param
    (
		[Parameter(ParameterSetName='Status')]
		[ValidateSet('', 'Any', 'Active', 'Historical')]
		[string]$Status,
		
		[Parameter(ParameterSetName='AssignedTo')]
		[ValidateNotNullOrEmpty()]
        [string]$AssignedTo
		
	)		
	
	Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		$filter = New-Object Tridion.ContentManager.CoreService.Client.ProcessesFilterData;
		$acvities = new-object Tridion.ContentManager.CoreService.Client.ActivityData;
		$readOption = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
		$readOption.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
		$processInstanceData = New-Object Tridion.ContentManager.CoreService.Client.ProcessInstanceData;
		$list = New-Object -TypeName System.Collections.Generic.List[Tridion.ContentManager.CoreService.Client.ProcessInstanceData];
					
        if ($client -ne $null)
        {
			switch($PsCmdlet.ParameterSetName)
			{
			    'Status'
				{
					Write-Verbose "Loading list of Workflow Items...";
					
					if($Status -eq $null -or $Status -eq '')
					{
						$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Any;				
					}
					else
					{
						$filter.ProcessType = $Status
					}
								
					$WorkflowItemDetail = _GetSystemWideList $client $filter;					
					return $WorkflowItemDetail
				}
			    'AssignedTo'
				{
					Write-Verbose "Loading Workflow items by AssignedTo '$AssignedTo'..."
					$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Active;
					$WorkflowItemDetail = _GetSystemWideList $client $filter;
					
					if ($AssignedTo -ne $null)
					{
						if($AssignedTo.StartsWith('tcm'))
						{						
							if ($WorkflowItemDetail -ne $null)
							{
								foreach($item in $WorkflowItemDetail)
								{
									$processInstanceData = $client.Read($item.Id,$readOption);
									$acvities = $processInstanceData.Activities | Select-Object -Last 1;
									$assignee = $acvities.Assignee.IdRef;
									if ($assignee -eq $AssignedTo)
									{
									  $list.Add($processInstanceData)
									}
								}
								return $list;
							}
							else
							{
								Write-Error "No active workflow item found.";
								return $null;
							}		
						}
						else
						{
							if ($WorkflowItemDetail -ne $null)
							{
								foreach($item in $WorkflowItemDetail)
								{
									$processInstanceData = $client.Read($item.Id,$readOption);
									$acvities = $processInstanceData.Activities | Select-Object -Last 1;
									$assignee = $acvities.Assignee.Title;
									if ($assignee -eq $AssignedTo)
									{
									  $list.Add($processInstanceData)
									}
								}
								return $list;
							}
							else
							{
								Write-Error "No active workflow item found.";
								return $null;
							}							
						}					
					}							
				}				
			}
        }
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}