#Requires -version 3.0
Set-StrictMode -Version Latest

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
function Publish-TridionItem
{
    <#
    .Synopsis
    Publishes an item to the specified target.
	
    .Inputs
    None.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Publish-TridionItem -Id 'tcm:1-59' -Target $publicationTarget
	Publishes the item with ID 'tcm:1-59' to the Publication Target stored in variable $publicationTarget.

    .Example
    Publish-TridionItem -Id 'tcm:1-59' -TargetId 'tcm:0-1-65537'
	Publishes the item with ID 'tcm:1-59' to Publication Target with ID 'tcm:0-1-65537' with normal priority.

    .Example
    Publish-TridionItem -Id 'tcm:1-59' -TargetId 'tcm:0-1-65537' -Priority High
	Publishes the item with ID 'tcm:1-59' to Publication Target with ID 'tcm:0-1-65537' with high priority.

    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI of the item to publish.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Id,

		# The TCM URI of the Publication Target to publish to
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=1)]
		[ValidateNotNullOrEmpty()]
        [string]$TargetId,
		
		# The item to publish.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithObject', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Item,

		# The Publication Target to publish to
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='WithObject', Position=1)]
		[ValidateNotNullOrEmpty()]
        [string]$Target,
		
		# The priority you wish to publish it with (Low, Medium, High)
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
		[ValidateSet('Low', 'Normal', 'High')]
		[string]$Priority = 'Normal'
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		if ($client -eq $null) { return; }
		
		$publishInstruction = New-Object Tridion.ContentManager.CoreService.Client.PublishInstructionData;
		$publishInstruction.RenderInstruction = New-Object Tridion.ContentManager.CoreService.Client.RenderInstructionData;
		$publishInstruction.ResolveInstruction = New-Object Tridion.ContentManager.CoreService.Client.ResolveInstructionData ;
		$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;

		switch($PsCmdlet.ParameterSetName)
		{
			'ById'
			{
				return $client.Publish($Id, $publishInstruction, $TargetId, $Priority, $readOptions);
			}
			
			'WithObject'
			{
				return $client.Publish($Item.Id, $publishInstruction, $Target.Id, $Priority, $readOptions);
			}
		}
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Unpublish-TridionItem
{
    <#
    .Synopsis
    Unpublishes an item from the specified target.
	
    .Inputs
    None.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Unpublish-TridionItem -Id 'tcm:1-59' -Target $publicationTarget
	Unpublishes the item with ID 'tcm:1-59' from the Publication Target stored in variable $publicationTarget.

    .Example
    Unpublish-TridionItem -Id 'tcm:1-59' -TargetId 'tcm:0-1-65537'
	Unpublishes the item with ID 'tcm:1-59' from Publication Target with ID 'tcm:0-1-65537' with normal priority.

    .Example
    Unpublish-TridionItem -Id 'tcm:1-59' -TargetId 'tcm:0-1-65537' -Priority High
	Unpublishes the item with ID 'tcm:1-59' from Publication Target with ID 'tcm:0-1-65537' with high priority.

    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI of the item to unpublish.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Id,

		# The TCM URI of the Publication Target to unpublish from
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=1)]
		[ValidateNotNullOrEmpty()]
        [string]$TargetId,
		
		# The item to unpublish.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='WithObject', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Item,

		# The Publication Target to unpublish from
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='WithObject', Position=1)]
		[ValidateNotNullOrEmpty()]
        [string]$Target,
		
		# The priority you wish to unpublish it with (Low, Medium, High)
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
		[ValidateSet('Low', 'Normal', 'High')]
		[string]$Priority = 'Normal'
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		if ($client -eq $null) { return; }
		
		$unpublishInstruction = New-Object Tridion.ContentManager.CoreService.Client.UnpublishInstructionData;
		$unpublishInstruction.ResolveInstruction = New-Object Tridion.ContentManager.CoreService.Client.ResolveInstructionData;
		$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;

		switch($PsCmdlet.ParameterSetName)
		{
			'ById'
			{
				return $client.Unpublish($Id, $unpublishInstruction, $TargetId, $Priority, $readOptions);
			}
			
			'WithObject'
			{
				return $client.Unpublish($Item.Id, $unpublishInstruction, $Target.Id, $Priority, $readOptions);
			}
		}
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Get-TridionPublishTransaction
{
    <#
    .Synopsis
    Gets a Publish Transaction by ID or a list of them based on a filter.

    .Description
    Gets a specific Publish Transaction (entry in the Publishing Queue) by its ID, or a list of all transactions that match the provided set of criteria.

    .Inputs
	[string] Id: the Publish Transaction with the given ID.
	OR
    [string] PublishState: the Publish state you want to filter on (Rendering, Success, Failed, etc.)
    [DateTime] StartDate: Only show Publish Transactions created after this date.
    [DateTime] EndDate: Only show Publish Transactions that occurred before this date.
    [int] PublicationID: Only show Publish Transactions for this Publication.
    [string] Priority: Only show Pubish Transactions with this Priority (Low, Normal, High)
    [int] Target: Only show Publish Transactions for this Publication Target
    [string] UserName: Only show Publish Transactions initiated by this user (including domain name)

    .Outputs
    Returns a list of Publish Transactions matching the given criteria

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
    .Example
    Get-TridionPublishTransaction
    Returns all Publish Transactions currently in the Publish Queue

	.Example
	Get-TridionPublishTransaction -Id 'tcm:0-2382-66560'
	Returns the Publish Transaction with the ID 'tcm:0-2382-66560'.
	
    .Example
    Get-TridionPublishTransaction -EndDate 3-23-2016
    Returns all Publish Transactions created before March 23, 2016.

    .Example
    Get-TridionPublishTransaction -UserName domain\name -PublishState Success
    Returns all Publish Transactions created by user 'domain\name' that were published successfully.

    .Example
    Get-TridionPublishTransaction -Priority Low | Remove-TridionPublishTransactions
    Removes all Publish Transactions with a low priority.

    #>

    [CmdletBinding(DefaultParameterSetName='ByFilter')]
    Param
    (
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById')]
		[string]$Id,
		
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
		[ValidateSet('CommittingDeployment', 'Deploying', 'Failed', 'InProgress', 'PreCommittingDeployment', 'PreparingDeployment', 
		'ReadyForTransport', 'Rendering', 'Resolving', 'ScheduledForDeployment', 'ScheduledForPublish', 'Success', 'Throttled', 
		'Transporting', 'UndoFailed', 'Undoing', 'Undone')]
        [string]$PublishState,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
        [DateTime]$EndDate,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]	
        [DateTime]$StartDate,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
        [int]$PublicationId,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
		[ValidateSet('Low', 'Normal', 'High')]
        [string]$Priority,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
        [int]$Target,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByFilter')]
        [string]$UserName
    )

    Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
    }

    Process
    {
		if ($client -ne $null)
        {
			switch($PsCmdlet.ParameterSetName)
			{
				'ById'
				{
					return Get-TridionItem $Id;
				}
				
				'ByFilter'
				{
					$filter = New-Object Tridion.ContentManager.CoreService.Client.PublishTransactionsFilterData;
					
					if ($PublishState)
					{
						Write-Verbose "Adding filter for PublishTransactionState: $PublishState";
						$filter.PublishTransactionState = $PublishState;
					}

					if ($EndDate)
					{
						Write-Verbose "Adding filter for EndDate: $EndDate";
						$filter.EndDate = $EndDate.ToUniversalTime();
					}

					if ($StartDate)
					{
						Write-Verbose "Adding filter for StartDate: $StartDate";
						$filter.StartDate = $StartDate.ToUniversalTime();
					}

					if ($PublicationId)
					{
						Write-Verbose "Adding filter to only show PublishTransactions for publication with ID: $PublicationId";
						$repo = New-Object Tridion.ContentManager.CoreService.Client.LinkToRepositoryData;
						$repo.IdRef = "tcm:0-$PublicationId-1";
						$filter.ForRepository = $repo;
					}

					if ($Priority)
					{
						Write-Verbose "Adding filter for priority: $Priority";
						$filter.Priority = $Priority;
					}
				
					if ($Target)
					{
						Write-Verbose "Adding filter to only show PublishTransactions for a Target with ID: $Target";
						$ptd = New-Object Tridion.ContentManager.CoreService.Client.LinkToPublicationTargetData;
						$ptd.IdRef = "tcm:0-$Target-65537";
						$filter.PublicationTarget = $ptd;
					}
						
					if ($UserName)
					{
						Write-Verbose "Adding filter to only show Publish Transctions created by a user with name: $UserName";
						$uid = Get-TridionUser -Title $UserName | Select-Object -ExpandProperty 'Id';
						$f = New-Object Tridion.ContentManager.CoreService.Client.LinkToUserData;
						$f.IdRef = $uid;
						$filter.PublishedBy = $f;
					}
			
				
					return $client.GetSystemWideList($filter);
				}
			}
		}
    }

    End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Remove-TridionPublishTransaction
{
    <#
    .Synopsis
    Deletes a given Publish Transaction from the Publish Queue.

    .Description
    Deletes a given Publish Transaction from the Publish Queue.

    .Inputs
    [string] Id: The ID of the Publish Transaction.
	OR
	[Tridion.ContentManager.CoreService.Client.PublishTransactionData] InputObject: the Publish Transaction to delete.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
    .Example
    Remove-TridionPublishTransactions tcm:0-4212900-66560
    Remove a Publish Transaction with this uri from the Publish Queue

    .Example
    Get-PublishQueueInfo -Priority Low -NoFormatting | select -ExpandProperty Id | Remove-TridionPublishTransactions
    Remove all Publish Transactions with a low priority
    #>

    [CmdletBinding(DefaultParameterSetName='ById')]
    Param
    (
     [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, ParameterSetName='ById')]		
     [string]$Id,

     [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, ParameterSetName='WithObject')]		
     [Tridion.ContentManager.CoreService.Client.PublishTransactionData]$Item
	)

    Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
    }
    Process
    {
		if ($client -ne $null)
        {
			switch($PsCmdlet.ParameterSetName)
			{
				'ById'
				{
					$client.Delete($Id) | Out-Null;
				}
				
				'WithObject'
				{
					$client.Delete($Item.Id) | Out-Null;
				}
			}
		}
    }

    End
	{
		Close-TridionCoreServiceClient $client;
	}
}



<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Publish-Tridion*, Unpublish-Tridion*, Get-Tridion*, Remove-Tridion* -Alias *