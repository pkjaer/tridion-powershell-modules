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
    param
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
    if ($script:CoreServiceHost -eq $null)
    {
        Set-TridionCoreServiceHost;
    }

    $result = New-Object -TypeName System.Object;
    $result | Add-Member -membertype noteproperty -name "ComputerName" -value $script:CoreServiceHost;
    $result | Add-Member -membertype noteproperty -name "Version" -value "2010";
    $result | Add-Member -membertype noteproperty -name "AssemblyPath" -value "$PSScriptRoot\Tridion.ContentManager.CoreService.Client.2010.dll";
    $result | Add-Member -membertype noteproperty -name "ClassName" -value "Tridion.ContentManager.CoreService.Client.SessionAwareCoreService2010Client";
    $result | Add-Member -membertype noteproperty -name "BaseUrl" -value ("http://{0}/webservices/CoreService.svc" -f $result.ComputerName);
    $result | Add-Member -membertype noteproperty -name "EndpointUrl" -value ("{0}/wsHttp_2010" -f $result.BaseUrl);
    $result | Add-Member -membertype noteproperty -name "UserName" -value ([Environment]::UserDomainName + "\" + [Environment]::UserName);
    
    
	# Find Tridion installation directory
	$tridionHome = $env:Tridion_cm_home;
	if (Test-Path $tridionHome)
	{
    	Write-Verbose "Located Tridion Content Manager installation at: $tridionHome. Checking for Core Service client.";
        
        # Detect client (introduced in 2011 SP1)
    	$clientPath = $tridionHome + "bin\\client\\Tridion.ContentManager.CoreService.Client.dll";
        if (Test-Path $clientPath)
        {
            Write-Verbose "2011 Core Service Client found.";
            
            $result.Version = "2011";
            $result.AssemblyPath = $clientPath;
            $result.ClassName = "Tridion.ContentManager.CoreService.Client.SessionAwareCoreServiceClient";
            $result.BaseUrl = ("http://{0}/webservices/CoreService2011.svc" -f $result.ComputerName);
            $result.EndpointUrl = ("{0}/wsHttp" -f $result.BaseUrl);;
            return $result;
        }
	}

    Write-Verbose "Defaulting to 2010 client as no client was found in the Tridion installation directory.";
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
    http://devpeterk.global.sdl.corp/Shared/PowerShell/

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

    #>
    Begin
    {
        # Load required .NET assemblies
        Add-Type -AssemblyName System.ServiceModel

        # Load information about the Core Service client available on this system
        $serviceInfo = Get-TridionCoreServiceInfo
        
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
    http://devpeterk.global.sdl.corp/Shared/PowerShell/

    .Example
    Get-TridionPublications

    .Example
    Get-TridionPublications | Select-Object Title, Id, Key
    
    #>
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
    param
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
    http://devpeterk.global.sdl.corp/Shared/PowerShell/

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
    param
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
    http://devpeterk.global.sdl.corp/Shared/PowerShell/

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
    param(
    
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            [string]$userName,
            
            [Parameter()]
            $description,
            
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
                
                $user = $client.GetDefaultData("User", $null);
                
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
                
                $readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
                $readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
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
    http://devpeterk.global.sdl.corp/Shared/PowerShell/

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
Export-ModuleMember Get-TridionCoreServiceInfo
Export-ModuleMember Get-TridionCoreServiceClient
Export-ModuleMember Get-TridionPublications
Export-ModuleMember Get-TridionUsers
Export-ModuleMember Get-TridionUser
Export-ModuleMember New-TridionUser
Export-ModuleMember Get-TridionCoreServiceHost
Export-ModuleMember Set-TridionCoreServiceHost
Export-ModuleMember Get-TridionItem
