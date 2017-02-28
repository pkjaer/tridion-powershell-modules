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
Function Convert-TridionApplicationData
{
    <#
    .Synopsis
    Converts the byte values of a piece of Application Data to a string.

    .Inputs
    The Application Data object, as returned by Get-TridionApplicationData.

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


Function Get-TridionApplicationData
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
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
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
		Close-TridionCoreServiceClient $client;
	}
}

Function Set-TridionApplicationData
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
	Sets the User Preferences XML for the given user.
	
	.Example
    Set-TridionApplicationData -Subject "tcm:0-12-65552" -ApplicationData $AppDataObject
	Sets the User Preferences XML for the given user.

    #>
    [CmdletBinding(DefaultParameterSetName='ByData')]
    Param
    (
		# The application which stored the data
        [Parameter(Mandatory=$true, ParameterSetName='ByData')]
		[ValidateNotNullOrEmpty()]
        [string]$Application,
		
		[Parameter(Mandatory=$true, ParameterSetName='ByData')]
		[ValidateNotNull()]
		$Data,
		
		[Parameter(Mandatory=$true, ParameterSetName='ByAppData')]
		[ValidateNotNull()]
		$ApplicationData,

		# The subject the data should be attached to
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Subject
	)
	
	Begin
	{
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			switch($PsCmdlet.ParameterSetName)
			{
				'ByData' 
				{
					$ada = New-Object Tridion.ContentManager.CoreService.Client.ApplicationDataAdapter -ArgumentList @($Application, $Data)
					if ($ada -ne $null)
					{
						$client.SaveApplicationData($Subject, @($ada.ApplicationData));
					}
				}
				
				'ByAppData' 
				{
					$client.SaveApplicationData($Subject, @($ApplicationData));
				}
			}
		}
    }
	
	End
	{
		Close-TridionCoreServiceClient $client;
	}
}

Function Remove-TridionApplicationData
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
		$client = Get-TridionCoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
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
		Close-TridionCoreServiceClient $client;
	}
}

<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Convert-TridionApplicationData
Export-ModuleMember Get-TridionApplicationData
Export-ModuleMember Set-TridionApplicationData
Export-ModuleMember Remove-TridionApplicationData