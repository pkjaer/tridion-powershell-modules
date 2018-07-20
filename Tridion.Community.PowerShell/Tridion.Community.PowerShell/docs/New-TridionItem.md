---
external help file: Tridion.Community.PowerShell.CoreService.dll-Help.xml
Module Name: Tridion.Community.PowerShell.CoreService
online version:
schema: 2.0.0
---

# New-TridionItem

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

```
New-TridionItem [-ItemType] <ItemType> [-Name] <String> [-Parent] <String> [<CommonParameters>]
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

### -ItemType
The item type of the new item.

```yaml
Type: ItemType
Parameter Sets: (All)
Aliases:
Accepted values: None, Publication, Folder, StructureGroup, Schema, Component, ComponentTemplate, Page, PageTemplate, TargetGroup, Category, Keyword, TemplateBuildingBlock, BusinessProcessType, VirtualFolder, PublicationTarget, TargetType, TargetDestination, MultimediaType, User, Group, DirectoryService, DirectoryGroupMapping, Batch, MultipleOperations, PublishTransaction, WorkflowType, ApprovalStatus, ProcessDefinition, ProcessInstance, ProcessHistory, ActivityDefinition, ActivityInstance, ActivityHistory, WorkItem, UnknownByClient

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The title of the new item.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Title

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Parent
ID of the organizational item that will hold the new item.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Id

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### CoreService.ItemType
System.String


## OUTPUTS

### CoreService.IdentifiableObjectData


## NOTES

## RELATED LINKS
