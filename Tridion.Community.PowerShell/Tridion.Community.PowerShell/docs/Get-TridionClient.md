---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Get-TridionClient

## SYNOPSIS
Returns a Core Service Client that can be used to accomplish tasks that aren't covered by the existing cmdlets.

## SYNTAX

```
Get-TridionClient [[-ImpersonateUserName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns a Core Service Client that can be used to accomplish tasks that aren't covered by the existing cmdlets.


## EXAMPLES

### Example 1
```powershell
PS C:\> $client = Get-TridionClient
```

Gets a client (based on the current settings) that can be used to communicate with the configured Core Service.

## PARAMETERS

### -ImpersonateUserName
The name (including domain) of the user to impersonate when accessing Tridion.

When omitted the current user will be executing all Tridion commands.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None


## OUTPUTS

### CoreService.ISessionAwareCoreService


## NOTES

## RELATED LINKS
