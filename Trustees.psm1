#Requires -version 2.0

$ErrorActionPreference = "Stop";

<#
**************************************************
* Public members
**************************************************
#>
function Get-TridionUser
{
    <#
    .Synopsis
    Gets information about the a specific Tridion user. Defaults to the current user.

    .Description
    Gets a UserData object containing information about the specified user within Tridion. 
    If called without any parameters, the currently logged on user will be returned.

    .Notes
    Example of properties available: Title, IsEnabled, LanguageId, LocaleId, Privileges (system administrator = 1), etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.Security.UserData object)

    .Inputs
    None.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.UserData].

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    Get-TridionUser | Format-List
    
    Returns a formatted list of properties of the currently logged on user.

    .Example
    Get-TridionUser | Select-Object Title, LanguageId, LocaleId, Privileges
    
    Returns the title, language, locale, and privileges (system administrator) of the currently logged on user.
    
    .Example
    Get-TridionUser "tcm:0-12-65552"
    
    Returns information about user #11 within Tridion (typically the Administrator user created during installation).
    
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [string]$id
    )

    
    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                if ([string]::IsNullOrEmpty($id))
                {
                    Write-Host "Loading current user...";
                    $client.GetCurrentUser();
                }
                else
                {
                    Write-Host "Loading Tridion user...";
                    if (!$client.IsExistingObject($id))
                    {
                        Write-Host "There is no such user in the system.";
                        return $null;
                    }
                    
                    $readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
                    $readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::WebdavUrls -bor [Tridion.ContentManager.CoreService.Client.LoadFlags]::Expanded;
                    $client.Read($id, $readOptions);
                }
            }
            finally
            {
                $client.Close() | Out-Null;
            }
        }
    }
}


function New-TridionGroup
{
    <#
    .Synopsis
    Adds a new Group to Tridion Content Manager.

    .Description
    Adds a new Group to Tridion Content Manager with the given name. 
    Optionally, you may specify a description for the Group. 
	It can also be a member of other Groups and only be available under specific Publications.

    .Notes
     Example of properties available: Id, Title, Scope, GroupMemberships, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.Security.GroupData object)

    .Inputs
    [string] name: the user name including the domain.
    [string] description: a description of the Group. Defaults to the $name parameter.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.GroupData], representing the newly created Group.

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    New-TridionGroup "Content Editors (NL)"
    
    Creates a new Group with the name "Content Editors (NL)". It is valid for all Publications.
    
    .Example
    New-TridionGroup "Content Editors (NL)" -description "Dutch Content Editors"
    
    Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is valid for all Publications.
    
    .Example
    New-TridionGroup "Content Editors (NL)" -description "Dutch Content Editors" | Format-List
    
    Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is valid for all Publications.
    Displays all of the properties of the resulting Group as a list.
	
	.Example
	New-TridionGroup -name "Content Editors (NL)" -description "Dutch Content Editors" -scope @("tcm:0-1-1", "tcm:0-2-1") -memberOf @("tcm:0-5-65568", "tcm:0-7-65568");
	
	Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is only usable in Publication 1 and 2.
	It is a member of the Author and Editor groups.    
    #>
    [CmdletBinding()]
    Param(
    
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            [string]$name,
            
            [Parameter()]
            [string]$description,
			
			[Parameter()]
			[string[]]$scope,
			
			[Parameter()]
			[string[]]$memberOf
    )

    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                if ($description -is [ScriptBlock]) 
                { 
                    [string]$groupDescription = $description.invoke() 
                }
                else
                { 
					$groupDescription = if ([string]::IsNullOrEmpty($description)) { $name } else { $description };
                }

                $readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
                $readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
                
				if ($client.GetDefaultData.OverloadDefinitions[0].IndexOf('string containerId') -gt 0)
				{
					$group = $client.GetDefaultData("Group", $null, $readOptions);
				}
				else
				{
					$group = $client.GetDefaultData("User", $null);
				}
                
                $group.Title = $name;
                $group.Description = $groupDescription;
				
				if (![string]::IsNullOrEmpty($scope))
				{
					foreach($publicationUri in $scope)
					{
						$link = New-Object Tridion.ContentManager.CoreService.Client.LinkWithIsEditableToRepositoryData;
						$link.IdRef = $publicationUri;
						$group.Scope += $link;
					}
				}
				
				if (![string]::IsNullOrEmpty($memberOf))
				{
					foreach($groupUri in $memberOf)
					{
						$groupData = New-Object Tridion.ContentManager.CoreService.Client.GroupMembershipData;
						$groupLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToGroupData;
						$groupLink.IdRef = $groupUri;
						$groupData.Group = $groupLink;
						$group.GroupMemberships += $groupData;
					}
				}
				
                $client.Create($group, $readOptions);
                Write-Host ("Group '{0}' has been created." -f $name);
            }
            finally
            {
                $client.Close() | Out-Null;
            }
        }
    }
}


function New-TridionUser
{
    <#
    .Synopsis
    Adds a new user to Tridion Content Manager.

    .Description
    Adds a new user to Tridion Content Manager with the given user name and description (friendly name). 
    Optionally, the user can be given system administrator rights with the Content Manager.

    .Notes
    Example of properties available: Id, Title, Key, PublicationPath, PublicationUrl, MultimediaUrl, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.PublicationData object)

    .Inputs
    [string] userName: the user name including the domain.
    [string] description: the friendly name of the user, typically the full name. Defaults to the $userName parameter.
    [bool] isAdmin: set to true if you wish to give the new user full administrator rights within the Content Manager. Defaults to $false.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.UserData], representing the newly created user.

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    New-TridionUser "GLOBAL\user01"
    
    Adds "GLOBAL\user01" to the Content Manager with a description matching the user name and no administrator rights.
    
    .Example
    New-TridionUser "GLOBAL\user01" "User 01"
    
    Adds "GLOBAL\user01" to the Content Manager with a description of "User 01" and no administrator rights.
    
    .Example
    New-TridionUser -username GLOBAL\User01 -isAdmin $true
    
    Adds "GLOBAL\user01" to the Content Manager with a description matching the user name and system administrator rights.

    .Example
    New-TridionUser "GLOBAL\user01" "User 01" $true | Format-List
    
    Adds "GLOBAL\user01" to the Content Manager with a description of "User 01" and system administrator rights.
    Displays all of the properties of the resulting user as a list.
    
    #>
    [CmdletBinding()]
    Param(
    
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            [string]$userName,
            
            [Parameter()]
            [string]$description,
            
            [Parameter()]
            [bool]$isAdmin = $false
    )

    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                if ($description -is [ScriptBlock]) 
                { 
                    [string]$userDescription = $description.invoke() 
                }
                else
                {
					$userDescription = if ([string]::IsNullOrEmpty($description)) { $userName } else { $description };
                }

                $readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
                $readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
                
				if ($client.GetDefaultData.OverloadDefinitions[0].IndexOf('string containerId') -gt 0)
				{
					$user = $client.GetDefaultData("User", $null, $readOptions);
				}
				else
				{
					$user = $client.GetDefaultData("User", $null);
				}
                
                $user.Title = $userName;
                $user.Description = $userDescription;

                if ($isAdmin)
                {
                    $user.Privileges = 1;
                }
                else
                {
                    $user.Privileges = 0;
                }
                
                $client.Create($user, $readOptions);
                Write-Host ("User '{0}' has been added." -f $userDescription);
            }
            finally
            {
                $client.Close() | Out-Null;
            }
        }
    }
}


Function Get-TridionUsers
{
    <#
    .Synopsis
    Gets a list of user within Tridion Content Manager.

    .Description
    Gets a list of users within Tridion Content Manager. 

    .Notes
    Example of properties available: Id, Title, IsEnabled, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.Security.UserData object)

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.UserData].

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    Get-TridionUsers
    
    Gets a list of all users.
    
    .Example
    Get-TridionUsers | Select-Object Id,Title,IsEnabled
    
    Gets the ID, Title, and enabled status of all users.
    
    .Example
    Get-TridionUsers | Where-Object { $_.IsEnabled -eq $false } | Select-Object Id,Title,IsEnabled | Format-List
    
    Gets the ID, Title, and enabled status of all disabled users in the system.
    Displays all of the properties as a list.
    
    #>
    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                Write-Host "Getting a list of Tridion users.";
                $filter = New-Object Tridion.ContentManager.CoreService.Client.UsersFilterData;
                $client.GetSystemWideList($filter);
            }
            finally
            {
                $client.Close() | Out-Null;
            }
        }
    }
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-TridionUser
Export-ModuleMember Get-TridionUsers
Export-ModuleMember New-TridionGroup
Export-ModuleMember New-TridionUser