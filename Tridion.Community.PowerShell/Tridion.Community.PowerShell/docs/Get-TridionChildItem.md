---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionChildItem

## SYNOPSIS
Return a list of items within a given organizational item.

## SYNTAX

```
Get-TridionChildItem [[-Parent] <PSObject>] [-Recurse] [-Level] [-ExpandProperties] [<CommonParameters>]
```

## DESCRIPTION
Return a list of items within a given organizational item, such as a Publication, Folder, or Structure Group.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionChildItem
```

Returns a list of all Publications in the system (that the user has access to).

### Example 2
```powershell
PS C:\> Get-TridionChildItem -Parent 'tcm:0-1-1'
```

Returns a list of the root items within the first Publication (Building Blocks, root Structure Group, etc.)

### Example 3
```powershell
PS C:\> Get-TridionChildItem -Parent 'tcm:0-1-1' -Recurse -Level
```

Returns a list of all items within the first Publication and includes a Level property on each item, indicating the level of nesting.

### Example 4
```powershell
PS C:\> Get-TridionPublication -Name '000 Empty Root' | Get-TridionChildItem -Recurse -Level
```

Returns a list of all items within the Publication named '000 Empty Root' and includes a Level property on each item, indicating the level of nesting.

### Example 5
```powershell
PS C:\> Get-TridionPublication -Name '000 Empty Root' | Get-TridionChildItem -Recurse -ExpandProperties | Where-Object { $_.IsEditable -eq $false }
```

Returns a list of all items that cannot currently be edited by this user, within the Publication named '000 Empty Root'.
The `ExpandProperties` parameter has to be included, as the `IsEditable` property is not loaded otherwise.

## PARAMETERS

### -ExpandProperties
If specified, loads all properties for each entry in the list.
By default, only some properties are loaded (for performance reasons).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Level
If specified, includes a Level property on each object to indicate the nested level of the item.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Parent
The parent organization item to query.
Either the TCM URI, WebDAV URL, or the parent object itself.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Recurse
If specified, also returns all child items in nested organizational items.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject
System.Management.Automation.SwitchParameter


## OUTPUTS

### System.Collections.Generic.List`1[[CoreService.IdentifiableObjectData, Tridion.Community.PowerShell.CoreService, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null]]


## NOTES

## RELATED LINKS
