---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionUser

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### All (Default)
```
Get-TridionUser [-ExpandProperties] [[-Filter] <ScriptBlock>] [<CommonParameters>]
```

### ByDescription
```
Get-TridionUser [-Description] <String> [-ExpandProperties] [<CommonParameters>]
```

### CurrentUser
```
Get-TridionUser [-Current] [<CommonParameters>]
```

### ByTitle
```
Get-TridionUser [-ExpandProperties] [-Name] <String> [<CommonParameters>]
```

### ById
```
Get-TridionUser [[-Id] <String>] [<CommonParameters>]
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

### -Current
{{Fill Current Description}}

```yaml
Type: SwitchParameter
Parameter Sets: CurrentUser
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
{{Fill Description Description}}

```yaml
Type: String
Parameter Sets: ByDescription
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ExpandProperties
{{Fill ExpandProperties Description}}

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
{{Fill Filter Description}}

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
The name of the item(s) to load.
This is slower than specifying the ID.

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

### System.Collections.Generic.IEnumerable`1[[CoreService.UserData, Tridion.Community.PowerShell.CoreService, Version=3.0.0.0, Culture=neutral, PublicKeyToken=null]]
CoreService.UserData


## NOTES

## RELATED LINKS
