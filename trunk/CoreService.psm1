#Requires -version 2.0

<#
**************************************************
* Private members
**************************************************
#>

Function Get-CoreServiceBinding
{
	$quotas = New-Object System.Xml.XmlDictionaryReaderQuotas;
	$quotas.MaxStringContentLength = 10485760;
	$quotas.MaxArrayLength = 10485760;
	$quotas.MaxBytesPerRead = 10485760;
	
	$httpBinding = New-Object System.ServiceModel.WSHttpBinding;
	$httpBinding.MaxReceivedMessageSize = 10485760;
	$httpBinding.ReaderQuotas = $quotas;
	
	$httpBinding.Security.Mode = "Message";
	$httpBinding.Security.Transport.ClientCredentialType = "Windows";
	return $httpBinding;
}


<#
**************************************************
* Public members
**************************************************
#>

Function Get-TridionCoreServiceHost
{
    return $script:CoreServiceHost;
}

Function Set-TridionCoreServiceHost
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName
    )

    Process
    {
        $newHost = $ComputerName;
        
        if ($newHost -eq $null -or $newHost -eq "")
        {
            $newHost = "localhost";
        }
        
        $script:CoreServiceHost = $newHost;
        Write-Host "Now using the Core Service at '$script:CoreServiceHost'."
    }
}


Function Get-TridionCoreServiceInfo
{   
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [string]$userName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
    )

    if ($script:CoreServiceHost -eq $null)
    {
        Set-TridionCoreServiceHost;
    }
	
	# Fallback scenario: 2010 client and endpoint
    $result = New-Object -TypeName System.Object;
    $result | Add-Member -membertype NoteProperty -name "ComputerName" -value $script:CoreServiceHost;
	$result | Add-Member -membertype NoteProperty -name "UserName" -value $userName;
    $result | Add-Member -membertype NoteProperty -name "Version" -value "2010";
    $result | Add-Member -membertype NoteProperty -name "AssemblyPath" -value "$PSScriptRoot\Tridion.ContentManager.CoreService.Client.2010.dll";
    $result | Add-Member -membertype NoteProperty -name "ClassName" -value "Tridion.ContentManager.CoreService.Client.SessionAwareCoreService2010Client";
    $result | Add-Member -membertype NoteProperty -name "BaseUrl" -value ("http://{0}/webservices/CoreService.svc" -f $result.ComputerName);
    $result | Add-Member -membertype NoteProperty -name "EndpointUrl" -value ("{0}/wsHttp_2010" -f $result.BaseUrl);

	# Check the installed version
	$tridionHome = $env:Tridion_cm_home;
	if (Test-Path $tridionHome)
	{
    	Write-Verbose "Located Tridion Content Manager installation at: $tridionHome. Checking for Core Service client.";

    	$clientPath = $tridionHome + "bin\\client\\CoreService\\Tridion.ContentManager.CoreService.Client.dll";
		if (Test-Path $clientPath)
		{
			$assembly = [Reflection.Assembly]::Loadfile($clientPath)
			$assemblyVersion = $assembly.GetName().Version
			
			if (($assemblyVersion.Major -eq 7) -and ($assemblyVersion.Minor -eq 1))
			{
				# Tridion 2013 SP1
				$result.Version = "2013 SP1";
				$result.AssemblyPath = $clientPath;
				$result.ClassName = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
				$result.BaseUrl = ("http://{0}/webservices/CoreService2013.svc" -f $result.ComputerName);
				$result.EndpointUrl = ("{0}/wsHttp" -f $result.BaseUrl);
			}
			else
			{
				# Tridion 2013 GA
				$result.Version = "2013";
				$result.AssemblyPath = $clientPath;
				$result.ClassName = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
				$result.BaseUrl = ("http://{0}/webservices/CoreService2012.svc" -f $result.ComputerName);
				$result.EndpointUrl = ("{0}/wsHttp" -f $result.BaseUrl);
			}
		}
		else
		{
			$clientPath = $tridionHome + "bin\\client\\Tridion.ContentManager.CoreService.Client.dll";
			if (Test-Path $clientPath)
			{
				# Tridion 2011
				$result.Version = "2011";
				$result.AssemblyPath = $clientPath;
				$result.ClassName = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
				$result.BaseUrl = ("http://{0}/webservices/CoreService2011.svc" -f $result.ComputerName);
				$result.EndpointUrl = ("{0}/wsHttp" -f $result.BaseUrl);
			}
		}
	}
	
	$script:CoreServiceInfo = $result;
    return $result;
}


Function Get-TridionCoreServiceClient
{
    <#
    .Synopsis
    Gets a client capable of accessing the Tridion Core Service.

    .Description
    Gets a session-aware Core Service client which uses the wsHttp binding to connect on the local machine.

    .Notes
    Make sure you call the Close method when you are done with the client (i.e. in a finally block).

    .Inputs
    None.

    .Outputs
    SDL Tridion 2011 SP1: Returns a client of type [Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient].
    Older versions: Returns a client of type [Tridion.ContentManager.CoreService.Client.SessionAwareCoreService2010Client].

    .Link
    Get the latest version of this script from the following URL:
    https://code.google.com/p/tridion-powershell-modules/

    .Example
    $client = Get-TridionCoreServiceClient;
    if ($client -ne $null)
    {
        try
        {
            $client.GetCurrentUser();
        }
        finally
        {
            $client.Close() | Out-Null;
        }
    }
	
	.Example
    $client = Get-TridionCoreServiceClient "Domain\UserName";
    if ($client -ne $null)
    {
        try
        {
            $client.GetCurrentUser();
        }
        finally
        {
            $client.Close() | Out-Null;
        }
    }

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [string]$userName = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
    )

    Begin
    {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.ServiceModel

        # Load information about the Core Service client available on this system
        $serviceInfo = Get-TridionCoreServiceInfo $userName
        
        Write-Host ("Connecting to the Core Service at {0}..." -f $serviceInfo.ComputerName);
        Write-Verbose ("Core Service URL: {0}" -f $serviceInfo.BaseUrl);
        
        # Load the Core Service Client
        $endpoint = New-Object System.ServiceModel.EndpointAddress -ArgumentList $serviceInfo.EndpointUrl
        $httpBinding = Get-CoreServiceBinding;
        [Reflection.Assembly]::LoadFrom($serviceInfo.AssemblyPath) | Out-Null;            
    }
    
    Process
    {
        try
        {
            $proxy = New-Object $serviceInfo.ClassName -ArgumentList $httpBinding, $endpoint;

            Write-Verbose ("Connecting to the Core Service as {0}" -f $serviceInfo.UserName);
            $proxy.Impersonate($serviceInfo.UserName) | Out-Null;
            
            return $proxy;
        }
        catch [System.Exception]
        {
            Write-Error $_;
            return $null;
        }
    }
}

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
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Id
    )

    Process
    {
        try
        {
            $client = Get-TridionCoreServiceClient
            if ($client.IsExistingObject($Id))
            {
                $client.Read($Id, (New-Object Tridion.ContentManager.CoreService.Client.ReadOptions));
            }
            else
            {
                Write-Host "There is no item with ID '$Id'.";
            }
        }
        finally
        {
            $client.Close() | Out-Null;
        }
    }
}


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
        [string]$Id
    )

    
    Process
    {
        $client = Get-TridionCoreServiceClient;
        if ($client -ne $null)
        {
            try
            {
                if ($Id -eq $null -or $Id -eq "")
                {
                    Write-Host "Loading current user...";
                    $client.GetCurrentUser();
                }
                else
                {
                    Write-Host "Loading Tridion user...";
                    if (!$client.IsExistingObject($Id))
                    {
                        Write-Host "There is no such user in the system.";
                        return $null;
                    }
                    
                    $readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
                    $readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::WebdavUrls -bor [Tridion.ContentManager.CoreService.Client.LoadFlags]::Expanded;
                    $client.Read($Id, $readOptions);
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
                if ($description –is [ScriptBlock]) 
                { 
                    [string]$groupDescription = $description.invoke() 
                }
                else
                { 
                    if ($description -eq "" -or $description -eq $null) 
                    { 
                        [string]$groupDescription = $name
                    }
                    else
                    {
                        [string]$groupDescription = $description
                    }
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
				
				if ($scope -ne "" -and $scope -ne $null)
				{
					foreach($publicationUri in $scope)
					{
						$link = New-Object Tridion.ContentManager.CoreService.Client.LinkWithIsEditableToRepositoryData;
						$link.IdRef = $publicationUri;
						$group.Scope += $link;
					}
				}
				
				if ($memberOf -ne "" -and $memberOf -ne $null)
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
                if ($description –is [ScriptBlock]) 
                { 
                    [string]$userDescription = $description.invoke() 
                }
                else
                { 
                    if ($description -eq "" -or $description -eq $null) 
                    { 
                        [string]$userDescription = $userName
                    }
                    else
                    {
                        [string]$userDescription = $description
                    }
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
Export-ModuleMember Get-TridionCoreServiceClient
Export-ModuleMember Get-TridionCoreServiceHost
Export-ModuleMember Get-TridionCoreServiceInfo
Export-ModuleMember Get-TridionItem
Export-ModuleMember Get-TridionPublications
Export-ModuleMember Get-TridionUser
Export-ModuleMember Get-TridionUsers
Export-ModuleMember New-TridionGroup
Export-ModuleMember New-TridionUser
Export-ModuleMember Set-TridionCoreServiceHost