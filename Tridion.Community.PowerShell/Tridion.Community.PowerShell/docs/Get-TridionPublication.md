---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionPublication

## SYNOPSIS
Gets a list of Publications present in Tridion Content Manager.

## SYNTAX

### All (Default)
```
Get-TridionPublication [-ExpandProperties] [[-Filter] <ScriptBlock>] [<CommonParameters>]
```

### ByPublicationType
```
Get-TridionPublication [[-PublicationType] <String>] [-ExpandProperties] [<CommonParameters>]
```

### ByTitle
```
Get-TridionPublication [-ExpandProperties] [-Name] <String> [<CommonParameters>]
```

### ById
```
Get-TridionPublication [[-Id] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets a list of Publications present in Tridion Content Manager, optionally filters by name or type.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionPublication
```

Returns a list of all Publications within Tridion.

### Example 2
```powershell
PS C:\> Get-TridionPublication -PublicationType 'Web'
```

Returns a list of all Web Publications within Tridion.

### Example 3
```powershell
PS C:\> Get-TridionPublication -Name '300 Translation*'
```

Returns a list of all Publications whose name starts with '300 Translation'.

### Example 4
```powershell
PS C:\> Get-TridionPublication -ExpandProperties -Filter { $_.MultimediaUrl -eq 'Images' }
```

Returns all Publications that have the default value in the "Images URL" field.
The `ExpandProperties` parameter is needed here, as the `MultimediaUrl` property is not loaded by default.

## PARAMETERS

### -ExpandProperties
If specified, loads all properties for each entry in the list.
By default, only some properties are loaded (for performance reasons).

```yaml
Type: SwitchParameter
Parameter Sets: All, ByPublicationType, ByTitle
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Allows you to specify a custom filter, which is evaluated for each Publication in the list. 
The filter must be a ScriptBlock which returns a boolean ($true if the item should be included in the result).
The special variable '$_' refers to the Publication.


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

### -PublicationType
The type of Publications to include in the list.

Examples include 'Web', 'Content', and 'Mobile'.

```yaml
Type: String
Parameter Sets: ByPublicationType
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

### System.String
System.Management.Automation.ScriptBlock


## OUTPUTS

### System.Collections.Generic.IEnumerable`1[[CoreService.PublicationData, Tridion.Community.PowerShell.CoreService, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null]]


## NOTES

## RELATED LINKS
