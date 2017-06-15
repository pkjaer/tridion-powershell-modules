<#
**************************************************
* Private utility methods
**************************************************
#>

Function _AddProperty($Object, $Name, $Value)
{
	Add-Member -InputObject $Object -MemberType NoteProperty -Name $Name -Value $Value;
}

Function _HasProperty($Object, $Name)
{
	return Get-Member -InputObject $Object -Name $Name -MemberType NoteProperty;
}

Function _NewObjectWithProperties([Hashtable]$properties)
{
	return New-Object -TypeName PSObject -Property $properties;
}

function _IsNullUri($Id) 
{
	return (!$Id -or $Id.Trim().ToLowerInvariant() -eq 'tcm:0-0-0')
}

function _GetIdFromInput($Value)
{
	return _GetPropertyFromInput $Value 'Id';
}

function _GetPropertyFromInput($Value, $PropertyName)
{
	if ($Value -is [ScriptBlock])
	{ 
		return $Value.invoke();
	}
	
	if ($Value -is [object])
	{
		if (Get-Member -InputObject $Value -Name $PropertyName)
		{
			return $Value.$PropertyName;
		}
	}
	
	return $Value;
}

function _GetMultipleIdsFromInput($Value)
{
	$result = @();
	foreach($val in @($Value))
	{
		$id = _GetIdFromInput $val;
		if (![string]::IsNullOrWhiteSpace($id))
		{ 
			$result += $id;
		}
	}
	return $result;
}

function _GetItemType($Id)
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

function _AssertItemType($Id, $ExpectedItemType)
{
	$itemType = _GetItemType $Id;
	if ($itemType -ne $ExpectedItemType)
	{
		throw "Unexpected item type '$itemType'. Expected '$ExpectedItemType'.";
	}
}

function _AssertItemTypeValid($ItemType)
{
	if ($ItemType -le 0 -or ![Enum]::IsDefined([Tridion.ContentManager.CoreService.Client.ItemType], $ItemType))
	{
		throw "Invalid item type: $ItemType";
	}
}

function _GetSystemWideList($Client, $Filter)
{
	return $Client.GetSystemWideList($Filter);
}

function _IsExistingItem($Client, $Id)
{
	return $Client.IsExistingObject($Id);
}

function _GetItem($Client, $Id)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	$readOptions.LoadFlags = 'WebDavUrls,Expanded,IncludeAllowedActions';
	return $Client.Read($Id, $readOptions);
}

function _GetDefaultData($Client, $ItemType, $Parent, $Name = $null)
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
	
	if ($Name -and $result)
	{
		$result.Title = $Name;
	}
	return $result;
}

function _SaveItem($Client, $Item, $IsNew)
{
	$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
	if ($IsNew)
	{
		return $Client.Create($Item, $readOptions);	
	}
	else 
	{
		return $Client.Save($Item, $readOptions);
	}	
}

function _DeleteItem($Client, $Id)
{
	$Client.Delete($Id);
}

function _ExpandPropertiesIfRequested($List, $ExpandProperties)
{
	if ($ExpandProperties -and $List)
	{
		return $List | Get-TridionItem;
	}
	return $List;
}
