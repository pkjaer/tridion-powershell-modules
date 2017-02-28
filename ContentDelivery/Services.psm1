#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

$ErrorActionPreference = 'Stop'

Function Add-Property($Object, $Name, $Value)
{
	Add-Member -InputObject $Object -MemberType NoteProperty -Name $Name -Value $Value;
}

Function New-ObjectWithProperties([Hashtable]$properties)
{
	$result = New-Object -TypeName System.Object;
	foreach($key in $properties.Keys)
	{
		Add-Property -Object $result -Name $key -Value $properties[$key];
	}
	return $result;
}



<#
**************************************************
* Public members
**************************************************
#>

function Get-ContentDeliveryToken
{
    <#
    .Synopsis
    Gets an authorization token for a given Content Delivery environment.

    .Description
    Gets an authorization token for a given Content Delivery environment by contacting the Token Service that is registered with the specified Discovery Service.

    .Example
	$discoveryServiceUrl = 'http://localhost:8082/discovery.svc';
	$token = Get-TridionContentDeliveryToken -DiscoveryServiceUrl $discoveryServiceUrl -ClientId 'cduser';
	
	Gets a token for 'cduser', prompting you for the client secret (input is masked).
	
	.Example
	$secret = Read-Host -AsSecureString
	$discoveryServiceUrl = 'http://localhost:8082/discovery.svc';
	$token = Get-TridionContentDeliveryToken -DiscoveryServiceUrl $discoveryServiceUrl -ClientId 'cduser' -ClientSecret $secret;
	
	Prompts for the client secret first (input is masked) and stores it in a SecureString variable.
	Then gets a token for the 'cduser' and stores it in the $token variable.

    .Example
	$secret = ConvertTo-SecureString "MyVisiblePassword" -AsPlainText -Force;
	$discoveryServiceUrl = 'http://localhost:8082/discovery.svc';
	$token = Get-TridionContentDeliveryToken -DiscoveryServiceUrl $discoveryServiceUrl -ClientId 'cduser' -ClientSecret $secret;
	
	Converts the client secret from plain text to a SecureString and uses it to get a token for the 'cduser'.
    #>    
	[CmdletBinding()]
    Param(
		# The URL to the Discovery Service for the environment.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string]$DiscoveryServiceUrl,
		
		# The Client ID to get a token for.
        [Parameter(Mandatory=$true)]
		[string]$ClientId,
		
		# The Client Secret used to authenticate the specified Client ID.
		# This is a SecureString so it isn't visible in the PowerShell prompt -- but it will still be sent in plain-text to the token service.
		[Parameter(Mandatory=$true)]
		[SecureString]$ClientSecret 
	)

	Process
	{
		$DiscoveryServiceUrl = $DiscoveryServiceUrl.TrimEnd('/');
		Write-Verbose "Contacting Discovery Service at: $DiscoveryServiceUrl";
		
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

function Test-ContentDeliveryServices
{
    <#
    .Synopsis
	Tests the availability of the various Tridion Content Delivery services.
	
	.Description
	Tests the availability of all services exposed by the specified Discovery Service.

    .Example
	Test-TridionContentDeliveryServices -DiscoveryServiceUrl $discoveryServiceUrl -Token $token
	
	Tests the services exposed by the specified Discovery Service, using a token previously retrieved using Get-TridionContentDeliveryToken.
	
	.Example
	Test-TridionContentDeliveryServices -DiscoveryServiceUrl $discoveryServiceUrl -Token $token | Where {$_.Status -ne 'Absent'} | fl -Property @('Name', 'Status', 'URL', 'Details')
	
	Tests all of the services, but filters out the 'Absent' (non-registered) ones and displays the results as a formatted list.
    #>    

    [CmdletBinding()]
    Param(
		# The URL to the Discovery Service for the environment.
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string]$DiscoveryServiceUrl,
		
		# The authorization token to use for the request (if secured). Use Get-TridionContentDeliveryToken to retrieve a token.
        [Parameter(Mandatory=$false)]
		$Token,
		
		# Include this switch to see the response from every service in the Details property.
		[switch] $IncludeResponses
	)
	
	Process
	{
		$DiscoveryServiceUrl = $DiscoveryServiceUrl.TrimEnd('/');
		$headers = @{};
		
		# Deal with OAuth (or not)
		if (!$Token)
		{
			Write-Warning "Contacting services anonymously. You should really secure your services with OAuth!"
		}
		else
		{
			if ((!$token.token_type) -or (!$token.access_token))
			{
				throw "Invalid token: $token";
				return;
			}
			
			$headers += @{ Authorization = $token.token_type + ' ' + $token.access_token };
		}
		
		$result = @();

		# Load a list of the capabilities from the Discovery Service 
		# This list includes all known capabilities, whether they are registered or not.
		try
		{
			$environment = Invoke-RestMethod -Uri "${DiscoveryServiceUrl}/Environment" -Method GET -Headers $headers;
			$capabilities = $environment.entry.link | Where { $_.title.EndsWith('Capability') -and $_.type -eq 'application/atom+xml;type=entry'};
		}
		catch
		{
			$errorMessage = $_.Exception.Message;
			Write-Host -Object "Discovery service returned an error: ${errorMessage}" -ForegroundColor Red -BackgroundColor Black;
			return;
		}
		
		# Progress variables
		$max = $capabilities.Count;
		$i = 0;
		
		foreach ($capability in $capabilities)
		{
			$i++;
			Write-Progress -Activity "Checking status of services" -Status $capability.title -PercentComplete ($i / $max * 100);
		
			$entry = New-ObjectWithProperties @{ 
				'Name' = $capability.title;
				'Status' = 'Not registered';
				'Details' = ''
				'URL' = '';
			};

			$result += $entry;
			$details = $null;
					
			try
			{
				# Load the details of the capability from the Discovery Service
				$details = Invoke-RestMethod -Uri ($discoveryServiceUrl + '/' + $capability.href) -Method GET -Headers $headers;
			} 
			catch 
			{
				$entry.Status = 'Absent'; # Capability isn't registered
				continue;
			}

			$entry.Status = 'Registered';
			$entry.URL = $details.entry.content.properties.URI;
			
			# Auto-registered services will have an entry but no URL, when they are stopped
			if (!$entry.URL) 
			{
				# WebCapability never has a URL so leave the status at 'Registered'
				if ($entry.Name -ne 'WebCapability')
				{
					$entry.Status = 'Stopped';
				}
				continue; 
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
				$entry.Status = 'Error';
				$entry.Details = $_.Exception.Message;
				continue;
			}
		}
		
		return $result | Sort Name;
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-ContentDeliveryToken
Export-ModuleMember Test-ContentDeliveryServices