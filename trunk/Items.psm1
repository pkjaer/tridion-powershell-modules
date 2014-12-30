#Requires -version 2.0

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
    https://code.google.com/p/tridion-powershell-modules/

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
		if ($client -ne $null) { $client.Close() | Out-Null; }
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
    https://code.google.com/p/tridion-powershell-modules/

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
		if ($client -ne $null) { $client.Close() | Out-Null; }
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-Item
Export-ModuleMember Get-Publications