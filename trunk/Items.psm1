#Requires -version 2.0

$ErrorActionPreference = "Stop";

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
function Get-TridionPublications
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

    .Example
    Get-TridionPublications | Select-Object Title, Id, Key
    
    #>
    [CmdletBinding()]
	Param()
	
    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                Write-Host "Loading list of Publications...";
                $filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationsFilterData;
                $client.GetSystemWideList($filter);
            }
            finally
            {
                $client.Close() | Out-Null;
            }
        }
    }
}


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
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    Get-TridionItem "tcm:2-44"
	Reads a Component.

    .Example
    Get-TridionItem "tcm:2-55-8"
	Reads a Schema.

    .Example
    Get-TridionItem "tcm:2-44" | Select-Object Id, Title
	Reads a Component and outputs just the ID and Title of it.
    
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $id
    )

    Process
    {
        try
        {
            $client = Get-TridionCoreServiceClient
            if ($client.IsExistingObject($id))
            {
                $client.Read($id, (New-Object Tridion.ContentManager.CoreService.Client.ReadOptions));
            }
            else
            {
                Write-Host "There is no item with ID '$id'.";
            }
        }
        finally
        {
            $client.Close() | Out-Null;
        }
    }
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-TridionItem
Export-ModuleMember Get-TridionPublications