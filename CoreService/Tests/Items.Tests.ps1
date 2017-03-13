Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

<#
**************************************************
* Tests
**************************************************
#>

Describe "Core Service Item Tests" {
	BeforeAll {
		$parent = Split-Path -Parent $here
		
		Get-Module Tridion-CoreService | Remove-Module
		$modulesToImport = @('Tridion-CoreService.psd1', 'Items.psm1');
		$modulesToImport | ForEach-Object { Import-Module (Join-Path $parent $_) -Force; }
	}

	# InModuleScope allows us to mock the private, non-exported functions in the module
	InModuleScope Items {
	
		# ***********************
		# Mock Items
		# ***********************
		$folder1 = [PSCustomObject]@{ Id = 'tcm:1-2-2'; Title = 'Building Blocks'};
		$page1 = [PSCustomObject]@{ Id = 'tcm:1-10-64'; Title = 'Page 1'};
		$publication1 = [PSCustomObject]@{ Id = 'tcm:0-1-1'; Title = 'Publication 1'; Parents = @()};
		$publication2 = [PSCustomObject]@{ Id = 'tcm:0-2-1'; Title = 'Publication 2'; Parents = @($publication1.Id)};
		$publication3 = [PSCustomObject]@{ Id = 'tcm:0-3-1'; Title = 'Web Publication 1'; Parents = @($publication2.Id)};
		$publication4 = [PSCustomObject]@{ Id = 'tcm:0-4-1'; Title = 'Web Publication 2'; Parents = @($publication2.Id)};
		$sg1 = [PSCustomObject]@{ Id = 'tcm:1-33-4'; Title = 'Root Structure Group'};
		$target1 = [PSCustomObject]@{ Id = 'tcm:0-1-65537'; Title = 'Publication Target 1'};
		$target2 = [PSCustomObject]@{ Id = 'tcm:0-2-65537'; Title = 'Publication Target 2'};

		$existingItems = @{
			$folder1.Id = $folder1;
			$page1.Id = $page1;
			$publication1.Id = $publication1;
			$publication2.Id = $publication2;
			$publication3.Id = $publication3;
			$publication4.Id = $publication4;
			$sg1.Id = $sg1;
			$target1.Id = $target1;
			$target2.Id = $target2;
		};
		
		$allPublications = @($publication1, $publication2, $publication3, $publication4);
		
		
		# ***********************
		# Mocks
		# ***********************
		Mock _GetDefaultData { 
			$result = [PSCustomObject]@{ Id = 'tcm:0-0-0'; Title = $Name; _ItemType = $ItemType};
			
			switch($ItemType) 
			{
				1 { Add-Member -InputObject $result -MemberType NoteProperty -Name 'Parents' -Value @();}
			}
			return $result; 
		}
		Mock _GetSystemWideList {
			if ($filter -is [Tridion.ContentManager.CoreService.Client.PublicationTargetsFilterData])
			{
				return @($target1, $target2);
			}
		
			if ($filter -is [Tridion.ContentManager.CoreService.Client.PublicationsFilterData])
			{
				$pubType = $filter.PublicationTypeName;
				switch ($pubType)
				{
					'Web' { return @($publication3, $publication4); }
					'Content' { return @($publication1, $publication2, $publication3); }
					default { return $allPublications; }
				}
				return @($publication1, $publication2);
			}
		}
		Mock _GetItem {
			if ($Id -in $existingItems.Keys)
			{
				return $existingItems[$Id];
			}
			
			throw "Item does not exist";
		}
		Mock _SaveItem { 
			$publicationId = 1;
			$itemType = $Item._ItemType;
			
			switch($itemType)
			{
				1 { $publicationId = 0; }
				2 {}
				64 {}
				default { throw "Unexpected item type: $itemType"; }
			}
			
			$random = Get-Random -Minimum 10 -Maximum 500;
			$Item.Id ="tcm:$publicationId-$random-$itemType";
			return $Item;
		}
		Mock _IsExistingItem { return ($Id -in $existingItems.Keys); }			
		Mock _DeleteItem { if (!$Id -in $existingItems.Keys) { throw "Item does not exist." } }
		Mock Close-TridionCoreServiceClient {}
		Mock Get-TridionCoreServiceClient { return [PSCustomObject]@{}; }
		
		
		# ***********************
		# Tests
		# ***********************
		Context "Get-TridionItem" {
			It "validates input parameters" {
				{ Get-TridionItem -Id $null } | Should Throw;
				{ Get-TridionItem -Id '' } | Should Throw;
			}
			
			It "disposes the client after use" {
				Get-TridionItem -Id $page1.Id | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports look-up by ID" {
				$item = Get-TridionItem -Id $page1.Id;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$item | Should Be $page1;
			}
			
			It "handles items that do not exist" {
				Get-TridionItem -Id 'tcm:0-99-64' | Should Be $null;
				Get-TridionItem -Id 'tcm:0-0-0' | Should Be $null;
			}
			
			It "supports piping in the ID" {
				$item = ($page1.Id | Get-TridionItem);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $page1.Id };
				$item | Should Be $page1;
			}
			
			It "supports piping in the ID as object" {
				$item = ($page1 | Get-TridionItem);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $page1.Id };
				$item | Should Be $page1;
			}
			
			It "supports piping in the ID by property name" {
				$testInput = [PSCustomObject]@{ Id = $page1.Id };
				$item = ($testInput | Get-TridionItem);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $page1.Id };
				$item | Should Be $page1;
			}
		}

		Context "Get-TridionPublication" {
			It "validates input parameters" {
				{ Get-TridionPublication -Id $null } | Should Throw;
				{ Get-TridionPublication -Id '' } | Should Throw;
				{ Get-TridionPublication -Id 'tcm:2-8-8' } | Should Throw "Unexpected item type '8'. Expected '1'.";
				{ Get-TridionPublication -Id 'tcm:2-1' } | Should Throw "Unexpected item type '16'. Expected '1'.";
			}
			
			It "disposes the client after use" {
				Get-TridionPublication | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports look-up by ID" {
				$publication = Get-TridionPublication -Id $publication1.Id;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$publication | Should Be $publication1;
			}
			
			It "supports look-up by name" {
				$publication = Get-TridionPublication -Name $publication1.Title;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publication | Should Be $publication1;
			}
			
			It "supports look-up by partial name" {
				$publications = Get-TridionPublication -Name 'Publication *';
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publications[0] | Should Be $publication1;
				$publications[1] | Should Be $publication2;
			}
			
			It "supports look-up by Publication Type" {
				$publications = Get-TridionPublication -PublicationType 'Web';
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publications | Should Be @($publication3, $publication4);
			}
			
			It "supports expanding properties in list by name" {
				# A list will typically only load partial data
				$publication = Get-TridionPublication -Name $publication2.Title -ExpandProperties;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$publication | Should Be $publication2;
			}

			It "supports expanding properties in list by Publication Type" {
				# A list will typically only load partial data
				$publications = Get-TridionPublication -PublicationType 'Web' -ExpandProperties;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				Assert-MockCalled _GetItem -Times 2 -Scope It;
				$publications.Count | Should Be 2;
				$publications[0] | Should Be $publication3;
				$publications[1] | Should Be $publication4;
			}

			It "supports piping in the ID by property name" {
				$testInput = [PSCustomObject]@{ Id = $publication1.Id };
				$item = ($testInput | Get-TridionPublication);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication1.Id };
				$item | Should Be $publication1;
			}			
			
			It "supports piping in the title by property name" {
				$testInput = [PSCustomObject]@{ Title = $publication2.Title };
				$item = ($testInput | Get-TridionPublication);
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$item | Should Be $publication2;
			}
			
			It "supports piping in the publication type by property name" {
				$testInput = @([PSCustomObject]@{ PublicationType = 'Web'}, [PSCustomObject]@{ PublicationType = 'Content' });
				$items = ($testInput | Get-TridionPublication);
				Assert-MockCalled _GetSystemWideList -Times 2 -Scope It -ParameterFilter { $Filter.PublicationTypeName -in @('Web', 'Content') };
				
				$items.Count | Should Be 5;
				$items[0] | Should Be $publication3;
				$items[1] | Should Be $publication4;
				$items[2] | Should Be $publication1;
				$items[3] | Should Be $publication2;
				$items[4] | Should Be $publication3;
			}
			
			It "returns a list of all Publications when called without parameters" {
				$publications = Get-TridionPublication;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publications | Should Be $allPublications;
			}
			
			It "handles items that do not exist" {
				Get-TridionPublication -Id 'tcm:0-99-1' | Should Be $null;
				Get-TridionPublication -Id 'tcm:0-0-0' | Should Be $null;
			}
			
			It "has aliases for backwards-compatibility (Get-TridionPublications => Get-TridionPublication)" {
				$alias = Get-Alias -Name Get-TridionPublications;
				$alias.Definition | Should Be 'Get-TridionPublication';
				
				# Check that it also works as expected (i.e. gets a list of items)
				$publications = Get-TridionPublications;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publications | Should Be $allPublications;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$publication = Get-TridionPublication -Title $publication1.Title;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$publication | Should Be $publication1;
			}
		}

		Context "Get-TridionPublicationTarget" {
			It "validates input parameters" {
				{ Get-TridionPublicationTarget -Id $null } | Should Throw;
				{ Get-TridionPublicationTarget -Id '' } | Should Throw;
				{ Get-TridionPublicationTarget -Id 'tcm:2-8-8' } | Should Throw "Unexpected item type '8'. Expected '65537'.";
				{ Get-TridionPublicationTarget -Id 'tcm:2-65537' } | Should Throw "Unexpected item type '16'. Expected '65537'.";
			}
			
			It "disposes the client after use" {
				Get-TridionPublicationTarget | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports look-up by ID" {
				$target = Get-TridionPublicationTarget -Id $target1.Id;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$target | Should Be $target1;
			}
			
			It "supports look-up by title" {
				$target = Get-TridionPublicationTarget -Name $target1.Title;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$target | Should Be $target1;
			}
			
			It "supports getting a list when called without parameters" {
				$targets = Get-TridionPublicationTarget;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$targets | Should Be @($target1, $target2);
			}
			
			It "supports expanding properties in list" {
				# A list will typically only load partial data
				$target = Get-TridionPublicationTarget -Name $target2.Title -ExpandProperties;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$target | Should Be $target2;
			}
			
			It "supports piping in the ID by property name" {
				$testInput = [PSCustomObject]@{ Id = $target1.Id };
				$item = ($testInput | Get-TridionPublicationTarget);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $target1.Id };
				$item | Should Be $target1;
			}			
			
			It "supports piping in the title by property name" {
				$testInput = [PSCustomObject]@{ Title = $target1.Title };
				$item = ($testInput | Get-TridionPublicationTarget);
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$item | Should Be $target1;
			}			
			
			It "supports piping in the title values" {
				$testInput = @($target1.Title, $target2.Title);
				$items = ($testInput | Get-TridionPublicationTarget);
				Assert-MockCalled _GetSystemWideList -Times 2 -Scope It;
				$items.Count | Should Be 2;
				$items[0] | Should Be $target1;
				$items[1] | Should Be $target2;
			}			
			
			It "handles items that do not exist" {
				Get-TridionPublicationTarget -Id 'tcm:0-99-65537' | Should Be $null;				
				Get-TridionPublicationTarget -Id 'tcm:0-0-0' | Should Be $null;
			}
			
			It "has aliases for backwards-compatibility (Get-TridionPublicationTargets => Get-TridionPublicationTarget)" {
				$alias = Get-Alias -Name Get-TridionPublicationTargets;
				$alias.Definition | Should Be 'Get-TridionPublicationTarget';
				
				# Check that it also works as expected (i.e. gets a list of items)
				$targets = Get-TridionPublicationTargets;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$targets | Should Be @($target1, $target2);
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$target = Get-TridionPublicationTarget -Title $target1.Title;
				Assert-MockCalled _GetSystemWideList -Times 1 -Scope It;
				$target | Should Be $target1;
			}
		}

		Context "New-TridionItem" {
			It "validates input parameters" {
				{ New-TridionItem -ItemType $null -Name 'Test'} | Should Throw 'Invalid item type: 0';
				{ New-TridionItem -ItemType -1 -Name 'Test'} | Should Throw 'Invalid item type: -1';
				{ New-TridionItem -ItemType 0 -Name 'Test'} | Should Throw 'Invalid item type: 0';
				{ New-TridionItem -ItemType 3 -Name 'Test'} | Should Throw 'Invalid item type: 3';
				{ New-TridionItem -ItemType 1 -Name $null} | Should Throw;
			}
			
			It "disposes the client after use" {
				New-TridionItem -ItemType 64 -Name 'Testing Dispose' | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "creates a new Page" {
				$itemTitle = 'My New Page';
				$item = New-TridionItem -ItemType 64 -Name $itemTitle -Parent $sg1.Id;
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 64) -and ($Name -eq $itemTitle) -and ($Parent -eq $sg1.Id) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It;
				$item.Title | Should Be $itemTitle;
				$item.Id.StartsWith('tcm:1-') | Should Be $true;
				_GetItemType $item.Id | Should Be 64;
			}

			It "supports piping in the parent" {
				$itemTitle = 'Testing pipeline parent';
				$item = (Get-TridionItem -Id $folder1.Id | New-TridionItem -ItemType 2 -Name $itemTitle);
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { $ItemType -eq 2 -and $Name -eq $itemTitle -and $Parent -eq $folder1.Id };
				Assert-MockCalled _SaveItem -Times 1 -Scope It;
				$item.Title | Should Be $itemTitle;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$itemTitle = 'Testing Title alias for Name';
				$item = New-TridionItem -ItemType 64 -Title $itemTitle -Parent $sg1.Id;
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 64) -and ($Name -eq $itemTitle) -and ($Parent -eq $sg1.Id) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It;
				$item.Title | Should Be $itemTitle;
				$item.Id.StartsWith('tcm:1-') | Should Be $true;
				_GetItemType $item.Id | Should Be 64;
			}
		}

		Context "New-TridionPublication" {
			It "validates input parameters" {
				{ New-TridionPublication -Name $null} | Should Throw;
				{ New-TridionPublication -Name ''} | Should Throw;
			}

			It "disposes the client after use" {
				New-TridionPublication -Name 'Testing Dispose' | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "creates a new Publication with the given title" {
				$itemTitle = 'Testing creation';
				$publication = New-TridionPublication -Name $itemTitle;
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 1) -and ($Name -eq $itemTitle) -and ($Parent -eq $null) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) };
				$publication.Title | Should Be $itemTitle;
				$publication.Id.StartsWith('tcm:0-') | Should Be $true;
				_GetItemType $publication.Id | Should Be 1;
			}
			
			It "creates a new Publication with a single parent" {
				$itemTitle = 'Testing creation with single parent';
				$publication = New-TridionPublication -Name $itemTitle -Parent $publication1;
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 1) -and ($Name -eq $itemTitle) -and ($Parent -eq $null) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) -and ($Item.Parents.Count -eq 1) };
				$publication.Title | Should Be $itemTitle;
				$publication.Id.StartsWith('tcm:0-') | Should Be $true;
				_GetItemType $publication.Id | Should Be 1;
				$publication.Parents[0].IdRef | Should Be $publication1.Id;
			}
			
			It "creates a new Publication with a multiple parents" {
				$itemTitle = 'Testing creation with multiple parents';
				$publication = New-TridionPublication -Name $itemTitle -Parent @($publication1, $publication2);
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 1) -and ($Name -eq $itemTitle) -and ($Parent -eq $null) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) -and ($Item.Parents.Count -eq 2) };
				$publication.Title | Should Be $itemTitle;
				$publication.Id.StartsWith('tcm:0-') | Should Be $true;
				_GetItemType $publication.Id | Should Be 1;
				$publication.Parents[0].IdRef | Should Be $publication1.Id;
				$publication.Parents[1].IdRef | Should Be $publication2.Id;
			}

			It "supports piping in the parent" {
				$itemTitle = 'Testing pipeline parent';
				$publication = (Get-TridionPublication -Id $publication4.Id | New-TridionPublication -Name $itemTitle);
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { $ItemType -eq 1 -and $Name -eq $itemTitle -and $Parent -eq $null };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) -and ($Item.Parents.Count -eq 1) };
				$publication.Title | Should Be $itemTitle;
				$publication.Parents[0].IdRef | Should Be $publication4.Id;
			}

			It "supports piping in multiple parents" {
				$itemTitle = 'Testing pipeline parent';
				$publication = Get-TridionPublication -PublicationType 'Web' | New-TridionPublication -Name $itemTitle;
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { $ItemType -eq 1 -and $Name -eq $itemTitle -and $Parent -eq $null };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) -and ($Item.Parents.Count -eq 2) };
				$publication.Title | Should Be $itemTitle;
				$publication.Parents[0].IdRef | Should Be $publication3.Id;
				$publication.Parents[1].IdRef | Should Be $publication4.Id;
			}

			It "has aliases for backwards-compatibility (Parents => Parent)" {
				$itemTitle = 'Testing creation with multiple parents';
				$publication = New-TridionPublication -Title $itemTitle -Parents @($publication1, $publication2);
				Assert-MockCalled _GetDefaultData -Times 1 -Scope It -ParameterFilter { ($ItemType -eq 1) -and ($Name -eq $itemTitle) -and ($Parent -eq $null) };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { ($Item.Title -eq $itemTitle) -and ($Item.Parents.Count -eq 2) };
				$publication.Title | Should Be $itemTitle;
				$publication.Id.StartsWith('tcm:0-') | Should Be $true;
				_GetItemType $publication.Id | Should Be 1;
				$publication.Parents[0].IdRef | Should Be $publication1.Id;
				$publication.Parents[1].IdRef | Should Be $publication2.Id;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$itemTitle = 'Testing Title alias for Name';
				$publication = New-TridionPublication -Title $itemTitle;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
				$publication.Title | Should Be $itemTitle;
			}
		}

		Context "Remove-TridionItem" {
			It "validates input parameters" {
				{ Remove-TridionItem -Id $null} | Should Throw;
				{ Remove-TridionItem -Id ''} | Should Throw;
			}
			
			It "supports positional parameter" {
				Remove-TridionItem $publication4.Id;
				Assert-MockCalled _DeleteItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication4.Id};
			}
			
			It "supports piping in the ID" {
				$publication4.Id | Remove-TridionItem;
				Assert-MockCalled _DeleteItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication4.Id};
			}
			
			It "supports piping in the ID as object" {
				$publication4 | Remove-TridionItem;
				Assert-MockCalled _DeleteItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication4.Id};
			}
			
			It "handles items that do not exist" {
				$itemId = 'tcm:0-99-32';
				Remove-TridionItem -Id $itemId;
				Assert-MockCalled _DeleteItem -Times 0 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It -ParameterFilter { $Id -eq $itemId};

				$itemId = 'tcm:0-0-0';
				Remove-TridionItem -Id $itemId;
				Assert-MockCalled _DeleteItem -Times 0 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It -ParameterFilter { $Id -eq $itemId};
			}
			
			It "has aliases for backwards-compatibility (Item => Id)" {
				Remove-TridionItem -Item $publication4;
				Assert-MockCalled _DeleteItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication4.Id};
			}
		}

		Context "Test-TridionItem" {
			It "validates input parameters" {
				{ Test-TridionItem -Id $null} | Should Throw;
				{ Test-TridionItem -Id ''} | Should Throw;
			}
			
			It "disposes the client after use" {
				Test-TridionItem $page1.Id | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports positional parameter" {
				$exists = (Test-TridionItem $publication4.Id);
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It -ParameterFilter { $Id -eq $publication4.Id};
				$exists | Should Be $true;
			}
			
			It "supports piping in the ID" {
				$exists = ($publication4.Id | Test-TridionItem);
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It #-ParameterFilter { $Id -eq $publication4.Id};
				$exists | Should Be $true;
			}
			
			It "supports piping in the ID as object" {
				$exists = ($publication4 | Test-TridionItem);
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It #-ParameterFilter { $Id -eq $publication4.Id};
				$exists | Should Be $true;
			}
			
			It "handles items that do not exist" {
				$itemId = 'tcm:0-99-32';
				$exists = Test-TridionItem -Id $itemId;
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It #-ParameterFilter { $Id -eq $itemId};
				$exists | Should Be $false;

				$itemId = 'tcm:0-0-0';
				Test-TridionItem -Id $itemId;
				Assert-MockCalled _IsExistingItem -Times 1 -Scope It #-ParameterFilter { $Id -eq $itemId};
				$exists | Should Be $false;
			}
		}
	}
}