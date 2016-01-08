#Requires -version 3.0

<#
**************************************************
* Public members
**************************************************
#>

function Get-User
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
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionUser | Format-List
    Returns a formatted list of properties of the currently logged on user.

    .Example
    Get-TridionUser | Select-Object Title, LanguageId, LocaleId, Privileges
    Returns the title, language, locale, and privileges (system administrator) of the currently logged on user.
    
    .Example
    Get-TridionUser 'tcm:0-12-65552'
    Returns information about user #11 within Tridion (typically the Administrator user created during installation).
    
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
        if ($client -ne $null)
        {
			if (-not $Id)
			{
				Write-Verbose "Loading current user...";
				$client.GetCurrentUser();
			}
			else
			{
				Write-Verbose "Loading Tridion user...";
				if (-not $client.IsExistingObject($Id))
				{
					Write-Error "The user '$Id' does not exist.";
					return $null;
				}
				
				$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
				$readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::WebdavUrls -bor [Tridion.ContentManager.CoreService.Client.LoadFlags]::Expanded;
				return $client.Read($Id, $readOptions);
			}
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}


Function Get-Users
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
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionUsers
    Gets a list of all users specifically added to the system (excludes predefined users like 'NT AUTHORITY\SYSTEM').
    
    .Example
    Get-TridionUsers -IncludePredefinedUsers | Select-Object Id,Title,IsEnabled
    Gets the ID, Title, and enabled status of all users.
    
    .Example
    Get-TridionUsers | Where-Object { $_.IsEnabled -eq $false } | Select-Object Id,Title,IsEnabled | Format-List
    Gets the ID, Title, and enabled status of all disabled users in the system.
    Displays all of the properties as a list.
    
    #>
    [CmdletBinding()]
    Param
    (
		# If set, the list of users will include pre-defined system users like 'NT AUTHORITY\SYSTEM' and 'MTSUser'.
        [Parameter()]
        [switch]$IncludePredefinedUsers
    )
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Getting a list of Tridion users.";
			$filter = New-Object Tridion.ContentManager.CoreService.Client.UsersFilterData;
			if (-not $IncludePredefinedUsers)
			{
				$filter.IsPredefined = $false;
			}
			$client.GetSystemWideList($filter);
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}


function New-Group
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
    [string] Name: the user name including the domain.
    [string] Description: a description of the Group. Defaults to the $Name parameter.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.GroupData], representing the newly created Group.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    New-TridionGroup -Name "Content Editors (NL)"
    Creates a new Group with the name "Content Editors (NL)". It is valid for all Publications.
    
    .Example
    New-TridionGroup -Name "Content Editors (NL)" -Description "Dutch Content Editors"
    Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is valid for all Publications.
    
    .Example
    New-TridionGroup -Name "Content Editors (NL)" -Description "Dutch Content Editors" | Format-List
    Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is valid for all Publications.
    Displays all of the properties of the resulting Group as a list.
	
	.Example
	New-TridionGroup -Name "Content Editors (NL)" -Description "Dutch Content Editors" -Scope @("tcm:0-1-1", "tcm:0-2-1") -MemberOf @("tcm:0-5-65568", "tcm:0-7-65568");
	Creates a new Group with the name "Content Editors (NL)" and a description of "Dutch Content Editors". 
	It is only usable in Publication 1 and 2.
	It is a member of the Author and Editor groups.    
	
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
			# The name of the new Group. This is displayed to end-users.
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
			[ValidateNotNullOrEmpty()]
            [string]$Name,
            
			# The description of the new Group. Generally used to indicate the purpose of the group. 
            [Parameter()]
            [string]$Description,
			
			# A list of URIs for the Publications in which the new Group applies.
			[Parameter()]
			[string[]]$Scope,
			
			# A list of URIs for the existing Groups that the new Group should be a part of.
			[Parameter()]
			[string[]]$MemberOf
    )
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}

    Process
    {
        if ($client -ne $null)
        {
			if ($Description -is [ScriptBlock]) 
			{ 
				[string]$groupDescription = $Description.invoke() 
			}
			else
			{ 
				$groupDescription = if ($Description) { $Description } else { $Name };
			}

			$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
			$readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
			
			if ($client.GetDefaultData.OverloadDefinitions[0].IndexOf('string containerId') -gt 0)
			{
				$group = $client.GetDefaultData("Group", $null, $readOptions);
			}
			else
			{
				$group = $client.GetDefaultData("Group", $null);
			}
			
			$group.Title = $Name;
			$group.Description = $groupDescription;
			
			if ($Scope)
			{
				foreach($publicationUri in $Scope)
				{
					$link = New-Object Tridion.ContentManager.CoreService.Client.LinkWithIsEditableToRepositoryData;
					$link.IdRef = $publicationUri;
					$group.Scope += $link;
				}
			}
			
			if ($MemberOf)
			{
				foreach($groupUri in $MemberOf)
				{
					$groupData = New-Object Tridion.ContentManager.CoreService.Client.GroupMembershipData;
					$groupLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToGroupData;
					$groupLink.IdRef = $groupUri;
					$groupData.Group = $groupLink;
					$group.GroupMemberships += $groupData;
				}
			}
			
			if ($PSCmdLet.ShouldProcess("Group { Name: '$($group.Title)', Description: '$($group.Description)' }", "Create")) 
			{
				$client.Create($group, $readOptions);
				Write-Verbose ("Group '{0}' has been created." -f $Name);
			}
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}	
}


function New-User
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
    [string] description: the friendly name of the user, typically the full name. Defaults to the $UserName parameter.
    [bool] isAdmin: set to true if you wish to give the new user full administrator rights within the Content Manager. Defaults to $false.

    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.UserData], representing the newly created user.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    New-TridionUser -UserName "GLOBAL\user01"
    Adds "GLOBAL\user01" to the Content Manager with a description matching the user name and no administrator rights.
    
    .Example
    New-TridionUser -UserName "GLOBAL\user01" -Description "User 01"
    Adds "GLOBAL\user01" to the Content Manager with a description of "User 01" and no administrator rights.
    
    .Example
    New-TridionUser -Username GLOBAL\User01 -MakeAdministrator
    Adds "GLOBAL\user01" to the Content Manager with a description matching the user name and system administrator rights.

    .Example
    New-TridionUser -UserName "GLOBAL\user01" -Description "User 01" -MakeAdministrator | Format-List
    Adds "GLOBAL\user01" to the Content Manager with a description of "User 01" and system administrator rights.
    Displays all of the properties of the resulting user as a list.
    
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
			# The username (including domain) of the new User
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
			[ValidateNotNullOrEmpty()]
            [string]$UserName,
			
            # The description (or 'friendly name') of the user. This is displayed throughout the UI.
            [Parameter()]
            [string]$Description,
			
            # If set, the new user will have system administrator privileges. Use with caution.
            [Parameter()]
            [switch]$MakeAdministrator
    )
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}

    Process
    {
        if ($client -ne $null)
        {
			if ($Description -is [ScriptBlock]) 
			{ 
				[string]$userDescription = $Description.invoke() 
			}
			else
			{
				$userDescription = if ([string]::IsNullOrEmpty($Description)) { $UserName } else { $Description };
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
			
			$user.Title = $UserName;
			$user.Description = $userDescription;

			if ($MakeAdministrator)
			{
				$user.Privileges = 1;
			}
			else
			{
				$user.Privileges = 0;
			}
			
			if ($PSCmdLet.ShouldProcess("User { Name: '$($user.Title)', Description: '$($user.Description)', Administrator: $MakeAdministrator }", "Create")) 
			{
				$client.Create($user, $readOptions);
				Write-Verbose ("User '{0}' has been added." -f $userDescription);
			}
        }
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
Export-ModuleMember Get-User
Export-ModuleMember Get-Users
Export-ModuleMember New-Group
Export-ModuleMember New-User