---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionPublicationTarget

## SYNOPSIS
Gets a list of Publication Targets present in Tridion Content Manager.

## SYNTAX

### All (Default)
```
Get-TridionPublicationTarget [[-Filter] <ScriptBlock>] [-ExpandProperties] [<CommonParameters>]
```

### ById
```
Get-TridionPublicationTarget [[-Id] <String>] [<CommonParameters>]
```

### ByTitle
```
Get-TridionPublicationTarget [-Name] <String> [-ExpandProperties] [<CommonParameters>]
```

## DESCRIPTION
Gets a list of Publication Targets present in Tridion Content Manager.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionPublicationTarget
```

Returns a list of all Publication Targets within Tridion.

### Example 2
```powershell
PS C:\> Get-TridionPublicationTarget -Name '*Staging*'
```

Returns a list of all Publication Targets that have 'Staging' in their name.

### Example 3
```powershell
PS C:\> Get-TridionPublicationTarget -Id 'tcm:0-2-65537'
```

Returns the Publication Target with ID 'tcm:0-2-65537'.

### Example 4
```powershell
PS C:\> Get-TridionPublicationTarget -ExpandProperties -Filter { $_.Priority -eq 'High' }
```

Returns a list of all Publication Targets with High priority.
The `ExpandProperties` parameter is included here as the `Priority` property is not loaded by default.



## PARAMETERS

### -ExpandProperties
If specified, loads all properties for each entry in the list.
By default, only some properties are loaded (for performance reasons).

```yaml
Type: SwitchParameter
Parameter Sets: All, ByTitle
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Allows you to specify a custom filter, which is evaluated for each Publication Target in the list. 
The filter must be a ScriptBlock which returns a boolean ($true if the item should be included in the result).
The special variable '$_' refers to the Publication Target.


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
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
System.Management.Automation.ScriptBlock


## OUTPUTS

### System.Collections.Generic.IEnumerable`1[[CoreService.PublicationTargetData, Tridion.Community.PowerShell.CoreService, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null]]


## NOTES

## RELATED LINKS
