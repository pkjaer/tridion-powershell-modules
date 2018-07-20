---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionGroup

## SYNOPSIS
Gets a list of Tridion Groups.

## SYNTAX

### All (Default)
```
Get-TridionGroup [-ExpandProperties] [[-Filter] <ScriptBlock>] [<CommonParameters>]
```

### ByDescription
```
Get-TridionGroup [-Description] <String> [-ExpandProperties] [<CommonParameters>]
```

### ByTitle
```
Get-TridionGroup [-ExpandProperties] [-Name] <String> [<CommonParameters>]
```

### ById
```
Get-TridionGroup [[-Id] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets a list of Tridion Groups, optionally filtered by title, description, or other criteria.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionGroup
```

Gets a list of all Groups within Tridion Content Manager.

### Example 2
```powershell
PS C:\> Get-TridionGroup -Id 'tcm:0-7-65568'
```

Gets the Group with ID 'tcm:0-7-65568' ('Editor').

### Example 3
```powershell
PS C:\> Get-TridionGroup -Name '*Editor*'
```

Gets a list of all Groups that have the word 'Editor' in their name.

### Example 4
```powershell
PS C:\> Get-TridionGroup -Description '*Editor*'
```

Gets a list of all Groups that have the word 'Editor' in their description.

### Example 5
```powershell
PS C:\> Get-TridionGroup -ExpandProperties -Filter { $_.GroupMemberships.Count -gt 0 }
```

Gets a list of all nested Groups (groups that are members of other groups).

The `ExpandProperties` switch is included here as the `GroupMemberships` property is not loaded by default.

## PARAMETERS

### -Description
Only return Groups that have a certain value in the Description field. Wildcards are permitted.

```yaml
Type: String
Parameter Sets: ByDescription
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### -ExpandProperties
If specified, loads all properties for each entry in the list.
By default, only some properties are loaded (for performance reasons).

```yaml
Type: SwitchParameter
Parameter Sets: All, ByDescription, ByTitle
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Allows you to specify a custom filter, which is evaluated for each Group in the list. 
The filter must be a ScriptBlock which returns a boolean ($true if the item should be included in the result).
The special variable '$_' refers to the Group.

```yaml
Type: ScriptBlock
Parameter Sets: All
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Id
The TCM URI or WebDAV URL of the item to retrieve.

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The name of the item(s) to load. This is slower than specifying the ID.
Wildcards are permitted.

```yaml
Type: String
Parameter Sets: ByTitle
Aliases: Title

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
System.Management.Automation.ScriptBlock


## OUTPUTS

### System.Collections.Generic.IEnumerable`1[[CoreService.GroupData, Tridion.Community.PowerShell.CoreService, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null]]
CoreService.GroupData


## NOTES

## RELATED LINKS
