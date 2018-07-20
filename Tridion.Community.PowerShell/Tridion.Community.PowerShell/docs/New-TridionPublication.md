---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# New-TridionPublication

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

```
New-TridionPublication -Name <String> [-Parent <String[]>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Name
The title of the new Publication.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Title

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Parent
The Publication(s) you wish to make this Publication a child of.
Accepts multiple values as an array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Parents

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
System.String[]


## OUTPUTS

### CoreService.PublicationData


## NOTES

## RELATED LINKS
