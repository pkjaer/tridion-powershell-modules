---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionApiVersion

## SYNOPSIS
Get the version of the Core Service API that is installed on the Content Manager.

## SYNTAX

```
Get-TridionApiVersion [<CommonParameters>]
```

## DESCRIPTION
Get the version of the Core Service API that is installed on the Content Manager.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionApiVersion
```

Get the version of the Core Service API that is installed on the Content Manager.

### Example 1
```powershell
PS C:\> $web8OrLater = (Get-TridionApiVersion).Major -ge 8
```

Sets a boolean variable indicating if the Content Manager is Web 8 or later.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None


## OUTPUTS

### System.Version


## NOTES

## RELATED LINKS
