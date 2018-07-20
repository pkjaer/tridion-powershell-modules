---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# New-TridionUser

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

```
New-TridionUser [-Name] <String> [[-Description] <String>] [[-MemberOf] <PSObject[]>] [-MakeAdministrator]
 [<CommonParameters>]
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

### -Description
The description (or 'friendly name') of the user.
This is displayed throughout the UI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MakeAdministrator
If set, the new user will have system administrator privileges.
Use with caution.

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

### -MemberOf
A list of URIs for the existing Groups that the new User should be a part of.
Supports also Titles of the groups.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The username (including domain) of the new User

```yaml
Type: String
Parameter Sets: (All)
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
System.Management.Automation.PSObject[]
System.Management.Automation.SwitchParameter


## OUTPUTS

### CoreService.UserData


## NOTES

## RELATED LINKS
