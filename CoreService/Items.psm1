#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>
function _Test-NullUri($Id) 
{
	return (!$Id -or $Id.Trim().ToLowerInvariant() -eq 'tcm:0-0-0')
}

function _Get-IdFromInput($Value)
{
	if ($Value -is [object])
	{
		if (Get-Member -InputObject $Value -Name 'Id')
		{
			return $Value.Id;
		}
	}
	return $Value;
}

function _Get-MultipleIdsFromInput($Value)
{
	$result = @();
	foreach($val in @($Value))
	{
		$result += _Get-IdFromInput $val;
	}
	return $result;
}

function _Get-ItemType($Id)
{
	if ($Id)
	{
		$parts = $Id.Split('-');
		switch($parts.Count)
		{
			2 { return 16; }
			3 { return [int]$parts[2] }
			4 { return [int]$parts[2] }
		}
	}
	
	return $null;
}

function _Assert-ItemType($Id, $ExpectedItemType)
{
	$itemType = _Get-ItemType $Id;
	if ($itemType -ne $ExpectedItemType)
	{
		throw "Unexpected item type '$itemType'. Expected '$ExpectedItemType'.";
	}
}

function _Assert-ItemTypeValid($ItemType)
{
	if ($ItemType -le 0 -or ![Enum]::IsDefined([Tridion.ContentManager.CoreService.Client.ItemType], $ItemType))
	{
		throw "Invalid item type: $ItemType";
	}
}

function _Get-SystemWideList($Client, $Filter)
{
	return $Client.GetSystemWideList($Filter);
}

function _Test-Item($Client, $Id)
{
    Process
    {
        return $Client.IsExistingObject($Id);
    }
}

function _Get-Item($Client, $Id)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	return $Client.Read($Id, $readOptions);
}

function _Get-PublicationTargets
{
    [CmdletBinding()]
	Param()
	
	Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationTargetsFilterData;
			return _Get-SystemWideList $client $filter;
        }
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function _Get-DefaultData($Client, $ItemType, $Parent, $Title = $null)
{
	if ($Client.GetDefaultData.OverloadDefinitions[0].IndexOf('ReadOptions readOptions') -gt 0)
	{
		$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
		$result = $Client.GetDefaultData($ItemType, $Parent, $readOptions);
	}
	else
	{
		$result = $Client.GetDefaultData($ItemType, $Parent);
	}
	
	if ($Title -and $result)
	{
		$result.Title = $Title;
	}
	return $result;
}

function _Save-Item($Client, $Item)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	return $Client.Save($Item, $readOptions);
}

function _Remove-Item($Client, $Id)
{
	$Client.Delete($Id);
}

function _Expand-PropertiesIfRequested($List, $ExpandProperties)
{
	if ($ExpandProperties)
	{
		return $List | Get-TridionItem;
	}
	return $List;
}

<#
**************************************************
* Public members
**************************************************
#>
Function Get-TridionItem
{
    <#
    .Synopsis
    Reads the item with the given ID.

    .Notes
    Example of properties available: Id, Title, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.IdentifiableObject object)

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.IdentifiableObject].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionItem -Id "tcm:2-44"
	Reads a Component.

    .Example
    Get-TridionItem -Id "tcm:2-55-8"
	Reads a Schema.

    .Example
    Get-TridionItem -Id "tcm:2-44" | Select-Object Id, Title
	Reads a Component and outputs just the ID and Title of it.
	
	.Example
	Get-TridionPublication | Get-TridionItem
	Reads every Publication within Tridion and returns the full data for each.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI or WebDAV URL of the item to retrieve.
        [Parameter(Mandatory=$true,  ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Id
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if (_Test-Item $client $Id)
			{
				return _Get-Item $client $Id;
			}
		}
		
		return $null;
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Get-TridionPublication
{
    <#
    .Synopsis
    Gets a list of Publications present in Tridion Content Manager.

    .Description
    Gets a list of PublicationData objects containing information about all Publications present in Tridion Content Manager.

    .Notes
    Example of properties available: Id, Title, Key, PublicationPath, PublicationUrl, MultimediaUrl, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.PublicationData object)

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.PublicationData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionPublication
	Returns a list of all Publications within Tridion.
	
	.Example
	Get-TridionPublication -PublicationType Web
	Returns a list of all 'Web' Publications within Tridion.

    .Example
    Get-TridionPublication | Select-Object Title, Id, Key
	Returns a list of the Title, Id, and Key of all Publications within Tridion.
    
    #>
    [CmdletBinding(DefaultParameterSetName='ByPublicationType')]
	Param(
		# The TCM URI of the Publication Target to load.
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Id,

		# The Title of the Publication Target to load. This is slower than specifying the ID.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByTitle', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Title,

		# The type of Publications to include in the list. Examples include 'Web', 'Content', and 'Mobile'. Omit to retrieve all Publications.
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ByPublicationType', Position=0)]
		[string] $PublicationType,
		
		[Parameter(ParameterSetName = 'ByTitle')]
		[Parameter(ParameterSetName = 'ByPublicationType')]
		[switch]$ExpandProperties
	)
	
	Begin
	{
        $client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		if ($client -eq $null) { return $null; }
	
		switch($PsCmdlet.ParameterSetName)
		{
			'ById' 
			{
				if (_Test-NullUri($Id)) { return $null; }
				_Assert-ItemType $Id 1;

				Write-Verbose "Loading Publication with ID '$Id'..."
				if (_Test-Item $client $Id)
				{
					return _Get-Item $client $Id;
				}
			}
			
			'ByTitle'
			{
				Write-Verbose "Loading Publication with title '$Title'..."
				$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationsFilterData;
				$list = _Get-SystemWideList $client $filter | ?{$_.Title -like $Title};
				return _Expand-PropertiesIfRequested $list $ExpandProperties;
			}
			
			'ByPublicationType'
			{
				Write-Verbose "Loading list of Publications...";
				$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationsFilterData;
				if ($PublicationType)
				{
					$filter.PublicationTypeName = $PublicationType;
				}
				$list = _Get-SystemWideList $client $filter;
				return _Expand-PropertiesIfRequested $list $ExpandProperties;
			}
		}

		return $null;
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Get-TridionPublicationTarget
{
    <#
    .Synopsis
    Gets information about a specific Tridion Publication Target.

    .Description
    Gets an object containing information about the specified Publication Target within Tridion.

    .Inputs
    [string] Id: The TCM URI of the Publication Target to load.
	OR
	[string] Title: The Title of the Publication Target to load.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.PublicationTargetData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules
	
	.Example
    Get-TridionPublicationTarget "tcm:0-1-65537"
    Returns the Publication Target with ID 'tcm:0-1-65537'.

    .Example
    Get-TridionPublicationTarget -Title "Staging"
    Returns the Publication Target named 'Staging'.
    
    #>
    [CmdletBinding(DefaultParameterSetName='ById')]
    Param
    (
		# The TCM URI of the Publication Target to load.
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Id,

		# The Title of the Publication Target to load. This is slower than specifying the ID.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByTitle', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Title,
		
		[switch]$ExpandProperties
    )

	Process
	{
		switch($PsCmdlet.ParameterSetName)
		{
			'ById' 
			{
				if (!$Id)
				{
					$list = _Get-PublicationTargets;
					return _Expand-PropertiesIfRequested $list $ExpandProperties;
				}
				
				if (_Test-NullUri($Id)) { return $null; }
				_Assert-ItemType $Id 65537;
			
				Write-Verbose "Loading Publication Target with ID '$Id'..."
				$result = Get-TridionItem $Id -ErrorAction SilentlyContinue;
				return $result;
			}
			
			'ByTitle'
			{
				Write-Verbose "Loading Publication Target with title '$Title'..."
				$list = Get-TridionPublicationTarget | ?{$_.Title -like $Title} | Select -First 1;
				if ($ExpandProperties)
				{
					return $list | Get-TridionItem;
				}
				return $list;
			}
		}
	}
}

function New-TridionItem
{
    <#
    .Synopsis
    Creates a new Tridion item of the specified type.
	
    .Inputs
    None.

    .Outputs
    Returns the newly created item.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    New-TridionItem -ItemType 4 -Title 'My new Structure Group' -Parent 'tcm:0-5-1'
    Creates a new Structure Group with the title "My new Structure Group" as a root Structure Group in Publication with ID 'tcm:0-5-1'.
    
    .Example
    New-TridionItem -ItemType 4 -Title 'My new Structure Group' -Parent 'tcm:6-11-4'
    Creates a new Structure Group with the title "My new Structure Group" within the parent Structure Group with ID 'tcm:6-11-4'.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The item type of the new item
        [Parameter(Mandatory=$true)]
        [int]$ItemType,
		
		# The title of the new item
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Title,
		
		# ID of the parent Publication / Structure Group / Folder / etc.
		[Parameter(ValueFromPipeline=$true)]
		$Parent
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		_Assert-ItemTypeValid $ItemType;

		$parentId = _Get-IdFromInput $Parent;
		$item = _Get-DefaultData $client $ItemType $parentId $Title;
        $result = _Save-Item $client $item;
		return $result;
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}


function New-TridionPublication
{
    <#
    .Synopsis
    Creates a new Publication.
	
    .Inputs
    None.

    .Outputs
    Returns the newly created Publication.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    New-TridionPublication -Title 'My new Publication'
    Creates a new Publication with the title "My new Publication".
    
    .Example
    New-TridionPublication -Title 'My new Publication' -Parents @('tcm:0-5-1', 'tcm:0-6-1')
    Creates a new Publication with the title "My new Publication" as a child of two existing Publications.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The title of the new Publication
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Title,
		
		# The Publication(s) you wish to make this Publication a child of. Accepts multiple values as an array.
		[Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias('Parents')]
		$Parent
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
		$listOfParents = @();
	}
	
	Process
	{
		$listOfParents += _Get-MultipleIdsFromInput $Parent;
	}
	
	End
	{
		$publication = _Get-DefaultData $client 1 $null $Title;
		if (!$publication) { throw "Unable to create Publication."}
		
		foreach($parent in $listOfParents)
		{
			$parentLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToRepositoryData;
			$parentLink.IdRef = $parent;
			$publication.Parents += $parentLink;
		}

        $result = _Save-Item $client $publication;
		
		Close-TridionCoreServiceClient $client;
		return $result;
	}
}

function Remove-TridionItem
{
    <#
    .Synopsis
    Deletes the given Tridion item, if possible.
	
    .Inputs
    None.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Remove-TridionItem -Id 'tcm:5-444-2'
    Deletes the folder with the given ID.
    
    .Example
    $folderId | Remove-TridionItem
    Deletes the folder with the ID stored in the variable $folderId.
    
    $folder | Remove-TridionItem
    Deletes the folder stored in the variable $folder.
    #>
    [CmdletBinding()]
    Param
    (
		# The title of the new Publication
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
		[Alias('Item')]
		[ValidateNotNullOrEmpty()]
        $Id
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		$itemId = _Get-IdFromInput $Id;
		if (_Test-Item $client $itemId)
		{
			Write-Verbose "Deleting item with ID '$itemId'..."
			_Remove-Item $client $itemId;
		}
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

function Test-TridionItem
{
    <#
    .Synopsis
    Checks if the item with the given ID exists.
	
    .Inputs
    None.

    .Outputs
    Returns a boolean type.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Test-TridionItem 'tcm:1-59'
    Returns $true if a Component with ID 'tcm:1-59' exists; $false otherwise.

    .Example
    Test-TridionItem 'tcm:1-155-64'
    Returns $true if a Page with ID 'tcm:1-155-64' exists; $false otherwise.

    .Example
    Test-TridionItem '/webdav/02 Publication'
    Returns if a Publication with WebDAV path '/webdav/02 Publication' exists; $false otherwise.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI of the item you wish to know exists. 
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position = 0)]
		[ValidateNotNullOrEmpty()]
        $Id
    )
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        return _Test-Item $client (_Get-IdFromInput $Id);
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
Set-Alias -Name Get-TridionPublications -Value Get-TridionPublication
Set-Alias -Name Get-TridionPublicationTargets -Value Get-TridionPublicationTarget
Export-ModuleMember -Function Get-Tridion*, New-Tridion*, Remove-Tridion*, Test-Tridion* -Alias *