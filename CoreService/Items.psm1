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
function Get-Publications
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
    Get-TridionPublications
	Returns a list of all Publications within Tridion.
	
	.Example
	Get-TridionPublications -PublicationType Web
	Returns a list of all 'Web' Publications within Tridion.

    .Example
    Get-TridionPublications | Select-Object Title, Id, Key
	Returns a list of the Title, Id, and Key of all Publications within Tridion.
    
    #>
    [CmdletBinding()]
	Param(
		# The type of Publications to include in the list. Examples include 'Web', 'Content', and 'Mobile'. Omit to retrieve all Publications.
		[string] $PublicationType
	)
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Loading list of Publications...";
			$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationsFilterData;
			if ($PublicationType)
			{
				$filter.PublicationTypeName = $PublicationType;
			}
			return $client.GetSystemWideList($filter);
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function Get-PublicationTargets
{
    <#
    .Synopsis
    Gets a list of Publication Targets present in Tridion Content Manager.

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.PublicationTargetData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionPublicationTargets
	Returns a list of all publication targets within Tridion.
	
    #>
    [CmdletBinding()]
	Param()
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Loading list of Publication Targets...";
			$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationTargetsFilterData;
			return $client.GetSystemWideList($filter);
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function Get-PublicationTarget
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
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ById', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Id,

		# The Title of the Publication Target to load. This is slower than specifying the ID.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByTitle', Position=0)]
		[ValidateNotNullOrEmpty()]
        [string]$Title
    )

	Process
	{
		switch($PsCmdlet.ParameterSetName)
		{
			'ById' 
			{
				if (!$Id.EndsWith('-65537'))
				{
					Write-Error "'$Id' is not a valid Publication Target URI.";
					return;
				}

				Write-Verbose "Loading Publication Target with ID '$Id'..."
				$result = Get-Item $Id -ErrorAction SilentlyContinue;
				if (-not $result)
				{
					Write-Error "Publication Target '$Id' does not exist.";
					return $null;
				}
				return $result;
			}
			
			'ByTitle'
			{
				Write-Verbose "Loading Publication Target with title '$Title'..."
				$result = Get-PublicationTargets | ?{$_.Title -eq $Title} | Select -First 1;
				if (-not $result)
				{
					Write-Error "There is no Publication Target named '$Title'.";
					return $null;
				}
				return $result;
			}
		}
	}
}

Function Get-Item
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
	Get-TridionPublications | Get-TridionItem
	Reads every Publication within Tridion and returns the full data for each.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI or WebDAV URL of the item to retrieve.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Id
    )
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if ($client.IsExistingObject($Id))
			{
				return $client.Read($Id, (New-Object Tridion.ContentManager.CoreService.Client.ReadOptions));
			}
			else
			{
				Write-Error "There is no item with ID '$Id'.";
			}
		}
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function Test-Item
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
        [Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Id
    )
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        return $client.IsExistingObject($Id);
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function New-Publication
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
        [Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Title,
		
		# ID(s) of the parent Publication(s)
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[string[]]$Parents
    )
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
		$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
		$publication = $client.GetDefaultData(1, $null, $readOptions);
		
		if ($Title)
		{
			$publication.Title = $Title;
		}		
		
		if ($Parents -ne $null)
		{
			$parentLinks = @();
			foreach($parent in $Parents)
			{
				$parentLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToRepositoryData;
				$parentLink.IdRef = $parent;
				$parentLinks += $parentLink;
			}
			$publication.Parents = $parentLinks;
		}
		
        $result = $client.Save($publication, $readOptions);
		return $result;
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-Item
Export-ModuleMember Get-Publications
Export-ModuleMember Get-PublicationTarget
Export-ModuleMember Get-PublicationTargets
Export-ModuleMember New-Publication
Export-ModuleMember Test-Item