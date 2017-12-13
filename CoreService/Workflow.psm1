#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

<#
**************************************************
* Public members
**************************************************
#>

function Get-TridionWorkflowItems
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
     [string] Status(Not Mandetory): Workflow ProcessInstanceData by status "Active" or "Hstoricle" (Bydefault is will show all the data)
	 [string] AssignedToById: The processInstanceData assigned to the given ID of User or Group.
     [string] AssignedToByTitle: The processInstanceData assigned to the given Title of User or Group. (For User provide : <domainname>\<username>)
	
    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.ProcessInstanceData].
	
    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
    .Example
    Get-TridionWorkflowItems
	Returns a list of all workflow items within Tridion (Active and Historical).
	
	.Example
    Get-TridionWorkflowItems -Status "Active"
	Returns a list of all workflow items within Tridion filtered By Status(Active) of The Workflow.
	
	.Example
	Get-TridionWorkflowItems -Status "Historical"
	Returns a list of all workflow items within Tridion filtered By Status(Historical) of The Workflow.
	
	.Example
    Get-TridionWorkflowItems -AssignedToById "tcm:0-1014-65552"
	Get-TridionWorkflowItems -AssignedToById "tcm:0-15-65568"
	Returns a list of all workflow items within Tridion filtered by AssignedTo given ID of User or Group.
	
	.Example
    Get-TridionWorkflowItems -AssignedToByTitle "TRIDIONDEV\San"
	Get-TridionWorkflowItems -AssignedToByTitle "Developer"
	Returns a list of all workflow items within Tridion filtered by AssignedTo given Title of User or Group.
	
	.Example
    Get-TridionWorkflowItems -Status "Active" | Select-Object Title, Id
	Get-TridionWorkflowItems -AssignedToById "tcm:0-1014-65552" | Select-Object Id,Title
	Returns a list of the Title, Id of all workflow items within Tridion filtered By Status(Active) or AssignedTo filter of The Workflow.
    #>
    [CmdletBinding(DefaultParameterSetName='Status')]
    Param
    (
		[Parameter(ParameterSetName='Status')]
		[ValidateSet('', 'Active', 'Historical')]
		[string]$Status,
		
		# The TCM URI of the Publication Target to load.
        [Parameter(ParameterSetName='AssignedToById')]
		[ValidateNotNullOrEmpty()]
        [string]$AssignedToById,
		
		# The Title of the Publication Target to load. This is slower than specifying the ID.
        [Parameter(ParameterSetName='AssignedToByTitle')]
		[ValidateNotNullOrEmpty()]
        [string]$AssignedToByTitle
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
					
					if($Status -eq $null)
					{
						$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Any;				
					}
					if($Status -eq "Active")
					{
						$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Active;				
					}
					if($Status -eq "Historical")
					{
						$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Historical;				
					}			
								
					$WorkflowItemDetail = $client.GetSystemWideList($filter);					
					return $WorkflowItemDetail
				}
			    'AssignedToById'
				{
					Write-Verbose "Loading Publication Target with Id '$AssignedToById'..."
					if ($AssignedToById -ne $null)
					{
						if(!$AssignedToById.EndsWith('-65552'))
						{						
							if(!$AssignedToById.EndsWith('-65568'))
							{
								Write-Error "'$AssignedToById' is not a valid User or Group TCM URI.";
								return;
							}
							else
							{
								$groupData = Get-TridionGroup -Id $AssignedToById
							    if($groupData -eq $null)
								{
									Write-Error "'$AssignedToById' is not a valid Group TCM URI.";
									return;
								}
							}
						}
						else
						{
							$userData = Get-TridionUser -Id $AssignedToById
							if($userData -eq $null)
							{
								Write-Error "'$AssignedToById' is not a valid User TCM URI.";
								return;
							}							
						}					
					}
					$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Active;
					$WorkflowItemDetail = $client.GetSystemWideList($filter);
					if ($WorkflowItemDetail -ne $null)
					{
						foreach($item in $WorkflowItemDetail)
						{
							$processInstanceData = $client.Read($item.Id,$readOption);
							$acvities = $processInstanceData.Activities | Select-Object -Last 1;
							$assignee = $acvities.Assignee.IdRef;
							if ($assignee -eq $AssignedToById)
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
				'AssignedToByTitle'
				{
					if ($AssignedToByTitle -ne $null)
					{
						if([regex]::Match($AssignedToByTitle,'.*?\\.*?').Success)
						{
							$userData = Get-TridionUser -Title $AssignedToByTitle
							if($userData -eq $null)
							{
								Write-Error "'$AssignedToByTitle' is not a valid User Name.";
								return;
							}
						}
						else
						{
							$groupData = Get-TridionGroup -Title $AssignedToByTitle
							if($groupData -eq $null)
							{
								Write-Error "'$AssignedToByTitle' is not a valid Group Name.";
								return;
							}
						}
						
					}
					Write-Verbose "Loading Publication Target with title '$AssignedToByTitle'..."
					$filter.ProcessType = [Tridion.ContentManager.CoreService.Client.ProcessType]::Active;
					$WorkflowItemDetail = $client.GetSystemWideList($filter);
					if ($WorkflowItemDetail -ne $null)
					{
						foreach($item in $WorkflowItemDetail)
						{
							$processInstanceData = $client.Read($item.Id,$readOption);
				     		$acvities = $processInstanceData.Activities | Select-Object -Last 1;
							$assignee = $acvities.Assignee.Title;
							if ($assignee -eq $AssignedToByTitle)
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
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}