#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>

Function Convert-ApplicationData
{
    <#
    .Synopsis
    Converts the byte values of a piece of Application Data to a string.

    .Inputs
    The Application Data object, as returned by Get-ApplicationData.

    .Outputs
    Returns the value of the application data as a string.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Convert-TridionApplicationData -ApplicationData $appData
	Returns the value of $appData.Data as a string (as opposed to a byte array).

    #>
    [CmdletBinding()]
    Param
    (
		# The application which stored the data
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $ApplicationData
	)
	
    Process
    {
		if ($ApplicationData.Data -eq $null) { return $null; }
		
		$arrBytes = $ApplicationData.Data;
		$dataType = $ApplicationData.TypeId;
		
		if (![string]::IsNullOrWhiteSpace($dataType))
		{
			if ($dataType.Contains("c:XmlDocument"))
			{
				return [System.Text.Encoding]::Unicode.GetString($arrBytes);
			} 
			elseif ($dataType.Contains("XmlDocument") -or $dataType.Contains("XmlElement"))
			{
				# Same as default, but we might want to treat it differently in the future
				return [System.Text.Encoding]::UTF8.GetString($arrBytes);
			}
			elseif ($dataType.StartsWith("image/"))
			{
				return [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($arrBytes);
			}
		}

		return [System.Text.Encoding]::UTF8.GetString($arrBytes);
	}
}


<#
**************************************************
* Public members
**************************************************
#>
Function Get-ApplicationData
{
    <#
    .Synopsis
    Reads the application data for the given item and application.

    .Inputs
    None.

    .Outputs
    Returns the application data as an object.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionApplicationData -Subject "tcm:0-12-65552" -Application "cme:UserPreferences"
	Returns the User Preferences XML for the given user.

    #>
    [CmdletBinding()]
    Param
    (
		# The application which stored the data
        [Parameter(Mandatory=$false)]
        [string]$Application,
		
		# The subject the data is attached to
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Subject
    )
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if ([string]::IsNullOrWhiteSpace($Application))
			{
				return $client.ReadAllApplicationData($Subject);
			}
			else
			{
				return $client.ReadApplicationData($Subject, $Application);
			}
		}
		
		return $null;
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

Function Set-ApplicationData
{
    <#
    .Synopsis
    Writes application data for the given item and application.

    .Inputs
    None.

    .Outputs
    None.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Set-TridionApplicationData -Subject "tcm:0-12-65552" -Application "cme:UserPreferences" -Data ""
	Returns the User Preferences XML for the given user.

    #>
    [CmdletBinding()]
    Param
    (
		# The application which stored the data
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Application,
		
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		$Data,

		# The subject the data should be attached to
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Subject
	)
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			$ada = New-Object Tridion.ContentManager.CoreService.Client.ApplicationDataAdapter -ArgumentList @($Application, $Data)
			if ($ada -ne $null)
			{
				$client.SaveApplicationData($Subject, @($ada.ApplicationData));
			}
		}
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

Function Remove-ApplicationData
{
    <#
    .Synopsis
    Deletes application data for the given item and application.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Remove-TridionApplicationData -Subject "tcm:0-12-65552" -Application "cme:UserPreferences"
	Deletes the User Preferences for the Administrator user.

    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
		# The application which stored the data
        [Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Application,
		
		# The subject the data should be attached to
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Subject
	)
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if ($PSCmdlet.ShouldProcess($Subject, "DeleteApplicationData"))
			{
				$client.DeleteApplicationData($Subject, $Application);
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
Export-ModuleMember Get-ApplicationData
Export-ModuleMember Set-ApplicationData
Export-ModuleMember Remove-ApplicationData
Export-ModuleMember Convert-ApplicationData