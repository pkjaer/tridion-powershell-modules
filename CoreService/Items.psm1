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
			Write-Verbose "Loading list of Publications...";
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
    Gets information about a specific Tridion publication target.

    .Description
    Gets a publication target object containing information about the specified publication target within Tridion.

    .Inputs
    None.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.PublicationTargetData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionPublicationTarget "Staging"
    Returns information about the publication target named 'Staging'.
	
	.Example
    Get-TridionPublicationTarget "tcm:2-12-65552"
    Returns information about publication target with the id 'tcm:2-12-65552'.
    
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$PublicationTarget
    )

	Write-Verbose "Loading Tridion publication target '$PublicationTarget'...";
	if ($PublicationTarget.StartsWith('tcm'))
	{
		$PublicationTargetObj = Get-Item $PublicationTarget
	}
	else
	{
		$PublicationTargetObj = Get-PublicationTargets | ?{$PublicationTarget -eq $_.Title} | Select -First 1
		if (-not $PublicationTargetObj)
		{
			Write-Error "The Publication Target '$PublicationTarget' does not exist."
			return $null;
		}
	}
	
	return $PublicationTargetObj
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
    Test-TridionItem 'tcm:1-155-5110'
    Returns if id 'tcm:1-155-5110' exists.

    .Example
    Test-TridionItem '/webdav/02 Publication'
    Returns if webdav path '/webdav/02 Publication' exists.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI of the user to load. If omitted, data for the current user is loaded instead.
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

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-Item
Export-ModuleMember Get-Publications
Export-ModuleMember Get-PublicationTarget
Export-ModuleMember Get-PublicationTargets
Export-ModuleMember Test-Item