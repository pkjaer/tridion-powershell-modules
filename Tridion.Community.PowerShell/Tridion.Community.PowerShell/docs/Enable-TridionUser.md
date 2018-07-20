---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# Enable-TridionUser

## SYNOPSIS
Enables the specified user in Tridion Content Manager.

## SYNTAX

```
Enable-TridionUser [-User] <PSObject> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Enables the specified user in Tridion Content Manager, after he or she has previously been disabled.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-TridionUser -Name 'EXAMPLE\isaacn' | Enable-TridionUser
```

Re-enables the user with username 'EXAMPLE\isaacn'.

### Example 2
```powershell
PS C:\> $user = Get-TridionUser -Id 'tcm:0-25-65552'; Enable-TridionUser -User $user
```

Re-enables the user with ID 'tcm:0-25-65552'.

### Example 3
```powershell
PS C:\> Enable-TridionUser -User "tcm:0-25-65552"
```

Re-enables the user with ID 'tcm:0-25-65552'.

### Example 4
```powershell
PS C:\> Get-TridionUser -Name 'EXAMPLE\*' | Enable-TridionUser
```

Re-enables all users in the "EXAMPLE" domain.

### Example 5
```powershell
PS C:\> Get-TridionUser -Name 'EXAMPLE\isaacn' | Enable-TridionUser -PassThru
```

Re-enables the user with username 'EXAMPLE\isaacn' and returns the updated user data.

## PARAMETERS

### -PassThru
If specified, the modified user is returned from the command.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -User
The user to enable.
Either the TCM URI, WebDAV URL, or the user object itself.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: Id

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

### System.Management.Automation.PSObject


## OUTPUTS

### CoreService.UserData


## NOTES

## RELATED LINKS
