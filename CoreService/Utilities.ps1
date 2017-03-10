<#
**************************************************
* Private utility methods
**************************************************
#>

Function _Add-Property($Object, $Name, $Value)
{
	Add-Member -InputObject $Object -MemberType NoteProperty -Name $Name -Value $Value;
}

Function _Has-Property($Object, $Name)
{
	return Get-Member -InputObject $Object -Name $Name -MemberType NoteProperty;
}

Function _New-ObjectWithProperties([Hashtable]$properties)
{
	$result = New-Object -TypeName System.Object;
	foreach($key in $properties.Keys)
	{
		_Add-Property -Object $result -Name $key -Value $properties[$key];
	}
	return $result;
}

function _Test-NullUri($Id) 
{
	return (!$Id -or $Id.Trim().ToLowerInvariant() -eq 'tcm:0-0-0')
}

function _Get-IdFromInput($Value)
{
	return _Get-PropertyFromInput $Value 'Id';
}

function _Get-PropertyFromInput($Value, $PropertyName)
{
	if ($Value -is [object])
	{
		if (Get-Member -InputObject $Value -Name $PropertyName)
		{
			return $Value.$PropertyName;
		}
	}
	
	return $Value;
}

function _Get-MultipleIdsFromInput($Value)
{
	$result = @();
	foreach($val in @($Value))
	{
		$result += _Get-IdFromInput $val;
	}
	return $result;
}

function _Get-ItemType($Id)
{
	if ($Id)
	{
		$parts = $Id.Split('-');
		switch($parts.Count)
		{
			2 { return 16; }
			3 { return [int]$parts[2] }
			4 { return [int]$parts[2] }
		}
	}
	
	return $null;
}

function _Assert-ItemType($Id, $ExpectedItemType)
{
	$itemType = _Get-ItemType $Id;
	if ($itemType -ne $ExpectedItemType)
	{
		throw "Unexpected item type '$itemType'. Expected '$ExpectedItemType'.";
	}
}

function _Assert-ItemTypeValid($ItemType)
{
	if ($ItemType -le 0 -or ![Enum]::IsDefined([Tridion.ContentManager.CoreService.Client.ItemType], $ItemType))
	{
		throw "Invalid item type: $ItemType";
	}
}

function _Get-SystemWideList($Client, $Filter)
{
	return $Client.GetSystemWideList($Filter);
}

function _Test-Item($Client, $Id)
{
    Process
    {
        return $Client.IsExistingObject($Id);
    }
}

function _Get-Item($Client, $Id)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	return $Client.Read($Id, $readOptions);
}

function _Get-DefaultData($Client, $ItemType, $Parent, $Title = $null)
{
	if ($Client.GetDefaultData.OverloadDefinitions[0].IndexOf('ReadOptions readOptions') -gt 0)
	{
		$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
		$result = $Client.GetDefaultData($ItemType, $Parent, $readOptions);
	}
	else
	{
		$result = $Client.GetDefaultData($ItemType, $Parent);
	}
	
	if ($Title -and $result)
	{
		$result.Title = $Title;
	}
	return $result;
}

function _Save-Item($Client, $Item)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	return $Client.Save($Item, $readOptions);
}

function _Remove-Item($Client, $Id)
{
	$Client.Delete($Id);
}

function _Expand-PropertiesIfRequested($List, $ExpandProperties)
{
	if ($ExpandProperties)
	{
		return $List | Get-TridionItem;
	}
	return $List;
}
