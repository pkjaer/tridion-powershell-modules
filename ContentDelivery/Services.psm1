#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

$ErrorActionPreference = 'Stop'

function _TestCapability
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true)]
		$capability,

		[Parameter(Mandatory = $true)]
		$headers,

		# Include this switch to see the response from every service in the Details property.
		[switch] $IncludeResponses
	)

	$discoveryServiceUrl = $script:Settings.DiscoveryServiceUrl;

	$entry = New-Object -TypeName PSObject -Property @{ 
		'Name' = $capability.title;
		'Status' = 'Not registered';
		'Details' = ''
		'URL' = '';
	};

	$details = $null;

	Write-Verbose "Testing capability $($capability.title)...";

	try
	{
		# Load the details of the capability from the Discovery Service
		$details = Invoke-RestMethod -Uri ($discoveryServiceUrl + '/' + $capability.href) -Method GET -Headers $headers;
	} 
	catch 
	{
		$entry.Status = 'Absent'; # Capability isn't registered
		return $entry;
	}

	$entry.Status = 'Registered';
	$entry.URL = $details.entry.content.properties.URI;

	# Handle 'localhost' registrations on remote machines
	if ($entry.URL -match 'localhost')
	{
		$host = ([System.Uri]$discoveryServiceUrl).Host;
		$entry.URL = $entry.URL.Replace('localhost', $host);
	}
	
	# Auto-registered services will have an entry but no URL, when they are stopped
	if (!$entry.URL) 
	{
		# WebCapability never has a URL so leave the status at 'Registered'
		if ($entry.Name -ne 'WebCapability')
		{
			$entry.Status = 'Stopped';
		}
		return $entry; 
	}
	
	try
	{
		# Contact the service for the capability to check if it's running / giving errors
		$response = Invoke-RestMethod -Uri $entry.URL -Method GET -Headers $headers;
		$entry.Status = "Running";
		
		# Optionally include the response from the service in the output
		if ($IncludeResponses)
		{
			$entry.Details = $response;
			$responseXml = $response -as [xml];
			if ($responseXml)
			{
				$entry.Details = $responseXml.OuterXml;
			}
		}
	}
	catch
	{
		if ($_.Exception.Message -match 'Unable to connect to the remote server')
		{
			$entry.Status = 'Stopped';
			return $entry;
		}

		$entry.Status = 'Error';
		$entry.Details = $_.Exception.Message;
		return $entry;
	}

	return $entry;
}


<#
**************************************************
* Public members
**************************************************
#>

function Get-TridionContentDeliverySettings
{
    <#
    .Synopsis
    Gets the settings that are used to contact the Content Delivery services.
	
    .Description
    Gets the settings that are used to contact the Content Delivery services, such as the URL to the Discovery service and the OAuth token to use.
    #>

	[CmdletBinding()]
	Param()

	if (!$script:Settings)
	{
		Reset-TridionContentDeliverySettings;
	}

	return $script:Settings;
}

function Reset-TridionContentDeliverySettings
{
    <#
    .Synopsis
    Resets the settings that are used to contact the Content Delivery services to the default values.
	
    .Description
    Resets the settings that are used to contact the Content Delivery services to the default values: localhost for the Discovery Service URL 
	and 'implementer' as the Client ID with its default value for Client Secret.
    #>
	[CmdletBinding()]
	Param(
		[Parameter()]
		[switch]$PassThru
	)

	$result = Set-TridionContentDeliverySettings `
		-DiscoveryServiceUrl 'http://localhost:8082/discovery.svc' `
		-ClientId $null -ClientSecret $null -PassThru;
	
	if ($PassThru) { return $result; }
}

function Set-TridionContentDeliverySettings
{
    <#
    .Synopsis
    Sets the settings to use when contacting the Content Delivery services.

    .Description
    Sets the settings to use when contacting the Content Delivery services, such as the URL to the Discovery service and the OAuth tokens to use.
    #>    
	[CmdletBinding()]
    Param(
		# The URL to the Discovery Service for the environment.
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$DiscoveryServiceUrl,
		
		# The Client ID to use. It is recommended to use a user in the 'implementer' role.
        [Parameter(Mandatory=$false)]
		[string]$ClientId,
		
		# The Client Secret to use when authenticating using OAuth.
		# This is a SecureString so it isn't visible in the PowerShell prompt -- but it will still be sent in plain-text to the token service.
		[Parameter(Mandatory=$false)]
		[SecureString]$ClientSecret,

		[Parameter()]
		[switch]$PassThru
	)

	Process
	{
		$script:Settings = New-Object -TypeName PSObject -Property @{
			DiscoveryServiceUrl = $DiscoveryServiceUrl.TrimEnd('/');
			ClientId = $ClientId;
			ClientSecret = $ClientSecret;
		}

		if ($PassThru) { return $script:Settings};
	}
}

function Get-TridionContentDeliveryToken
{
    <#
    .Synopsis
    Gets a custom authorization token for the configured Content Delivery environment.

    .Description
    Gets a custom authorization token for the configured Content Delivery environment by contacting the Token Service that is registered with the  Discovery Service.
    #>    
	[CmdletBinding()]
    Param(
		# The Client ID to get a token for.
        [Parameter(Mandatory=$true)]
		[string]$ClientId,
		
		# The Client Secret used to authenticate the specified Client ID.
		# This is a SecureString so it isn't visible in the PowerShell prompt -- but it will still be sent in plain-text to the token service.
		[Parameter(Mandatory=$true)]
		[SecureString]$ClientSecret 		
	)

	Begin
	{
		$settings = Get-TridionContentDeliverySettings;
	}

	Process
	{
		$discoveryServiceUrl = $settings.DiscoveryServiceUrl;
		Write-Verbose "Contacting Discovery Service at: $discoveryServiceUrl";
		
		$tokenCapability = Invoke-RestMethod -Uri "${discoveryServiceUrl}/Environment/TokenServiceCapability" -Method GET;
		$tokenServiceUrl = [string]$tokenCapability.entry.content.properties.URI;

		Write-Verbose "Creating credentials from the entered client secret..."
		$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($ClientId, $ClientSecret)
		$secret = $credentials.GetNetworkCredential().Password; # Will get the password in plain-text; hence no longer secure
		
		$parameters = @{
			client_id = $ClientId
			client_secret = $secret
			grant_type = 'client_credentials'
			resources = '/'
		};
		
		Write-Verbose "Contacting Token Service at: $tokenServiceUrl";
		$token = Invoke-RestMethod -Uri $tokenServiceUrl -Method POST -Body $parameters;
		return $token;
	}
}

function Test-TridionContentDeliveryServices
{
    <#
    .Synopsis
	Tests the availability of the various Tridion Content Delivery services.
	
	.Description
	Tests the availability of all services exposed by the specified Discovery Service.

    .Example
	Test-TridionContentDeliveryServices
	
	Tests all capabilities (services) of the configured Discovery Service and returns the result in a list with the properties: Name, URL, Status, and Details.
	
	.Example
	Test-TridionContentDeliveryServices | Where {$_.Status -ne 'Absent'} | fl -Property @('Name', 'Status', 'URL', 'Details')
	
	Tests all of the capabilities (services), but filters out the 'Absent' (non-registered) ones and displays the results as a formatted list.
    #>    

    [CmdletBinding()]
    Param(
		# Include this switch to see the response from every service in the Details property.
		[switch] $IncludeResponses
	)
	
	Begin
	{
		$settings = Get-TridionContentDeliverySettings;
	}

	Process
	{
		$discoveryServiceUrl = $settings.DiscoveryServiceUrl;
		$headers = @{};
		
		# Deal with OAuth (or not)
		if ($settings.ClientId)
		{
			$token = Get-TridionContentDeliveryToken -ClientId $settings.ClientId -ClientSecret $settings.ClientSecret;
		}

		if ($token)
		{
			$headers += @{ Authorization = $token.token_type + ' ' + $token.access_token };
		}
		
		$result = @();

		# Load a list of the capabilities from the Discovery Service 
		# This list includes all known capabilities, whether they are registered or not.
		try
		{
			$environment = Invoke-RestMethod -Uri "${discoveryServiceUrl}/Environment" -Method GET -Headers $headers;
			$capabilities = $environment.entry.link | Where-Object { $_.title.EndsWith('Capability') -and $_.type -eq 'application/atom+xml;type=entry'};
		}
		catch
		{
			throw "Discovery service returned an error: $($_.Exception.Message))";
		}
		
		# Progress variables
		$max = $capabilities.Count;
		$i = 0;

		foreach ($capability in $capabilities)
		{
			$i++;
			Write-Progress -Activity "Checking status of services" -Status $capability.title -PercentComplete ($i / $max * 100);
			$entry = _TestCapability $capability $headers -IncludeResponses:$IncludeResponses;
			if ($entry)
			{
				$result += $entry;
			}
		}
		
		return $result | Sort-Object Name;
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-*, Set-*, Reset-*, Test-*;