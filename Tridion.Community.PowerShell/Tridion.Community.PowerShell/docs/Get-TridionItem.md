---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionItem

## SYNOPSIS
Reads the item with the given ID.

## SYNTAX

```
Get-TridionItem [-Id] <String> [<CommonParameters>]
```

## DESCRIPTION
Reads the item with the given ID.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionItem -Id 'tcm:2-44'
```

Reads a Component.

### Example 2
```powershell
PS C:\> Get-TridionItem -Id '/webdav/100%20Schemas/Building%20Blocks/Schemas/Article.xsd'
```

Reads a Schema by its WebDAV URL.

### Example 3
```powershell
PS C:\> Get-TridionItem -Id 'tcm:2-44' | Select-Object Id, Title
```

Reads a Component and outputs just the ID and Title of it.

### Example 4
```powershell
PS C:\> Get-TridionPublication | Get-TridionItem
```

Reads every Publication within Tridion and returns the full data for each of them.
(Equivalent to `Get-TridionPublication -ExpandProperties`)


## PARAMETERS

### -Id
The TCM URI or WebDAV URL of the item to retrieve.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String


## OUTPUTS

### CoreService.IdentifiableObjectData


## NOTES

## RELATED LINKS
