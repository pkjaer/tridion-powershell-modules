Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

<#
**************************************************
* Tests
**************************************************
#>

Describe "Core Service Trustee Tests" {
	BeforeAll {
		$parent = Split-Path -Parent $here
		
		Get-Module Tridion-CoreService -All | Remove-Module;
		$modulesToImport = @('Tridion-CoreService.psd1', 'Trustees.psm1');
		$modulesToImport | ForEach-Object { Import-Module (Join-Path $parent $_) -Force; }
	}
	
	# InModuleScope allows us to mock the private, non-exported functions in the module
	InModuleScope Trustees {
	
		# ***********************
		# Mock Items
		# ***********************
		$user1 = [PSCustomObject]@{ Id = 'tcm:0-12-65552'; Title = 'DOMAIN\Administrator'; Description = 'Administrator'; Privileges = 1; IsEnabled = $true; };
		$user2 = [PSCustomObject]@{ Id = 'tcm:0-13-65552'; Title = 'DOMAIN\User02'; Description = 'User 02'; Privileges = 0; IsEnabled = $true; };
		$disabledUser = [PSCustomObject]@{ Id = 'tcm:0-69-65552'; Title = 'DOMAIN\DisabledUser'; Description = 'Disabled User'; Privileges = 0; IsEnabled = $false; };
		$enabledUser = [PSCustomObject]@{ Id = 'tcm:0-70-65552'; Title = 'DOMAIN\EnabledUser'; Description = 'Enabled User'; Privileges = 0; IsEnabled = $true; };
		$group1 = [PSCustomObject]@{ Id = 'tcm:0-2-65568'; Title = 'System Administrator'; Description = 'SDL Web Content Manager Administrators'; ExtensionProperties = @{'Custom'='G1'} };
		$group2 = [PSCustomObject]@{ Id = 'tcm:0-4-65568'; Title = 'Information Designer'; Description = 'Information Designer'; ExtensionProperties = @{'Custom'='G2'} };
		
		$existingItems = @{
			$user1.Id = $user1;
			$user2.Id = $user2;
			$disabledUser.Id = $disabledUser;
			$enabledUser.Id = $enabledUser;
			$group1.Id = $group1;
			$group2.Id = $group2;
		};
		
		
		# ***********************
		# Mocks
		# ***********************
		Mock _GetCurrentUser {
			return $user1;
		}
		Mock _GetTridionUsers {
			return @($user1, $user2);
		}
		Mock _GetTridionGroups {
			return @($group1, $group2);
		}
		Mock _GetDefaultData {
			$properties = @{
				Id = 'tcm:0-0-0';
				Title = $Name;
				Description = '';
				_ItemType = $ItemType;
			};

			switch($ItemType)
			{
				65552 { $properties += @{ IsEnabled = $true; Privileges = 0; GroupMemberships = @(); }; }
				65568 { $properties += @{ Scope = @(); GroupMemberships = @(); }; }
			}

			return _NewObjectWithProperties $properties;
		}
		Mock _GetSystemWideList {
			if ($filter.GetType().Name -eq 'UsersFilterData')
			{
				return @($user1, $user2);
			}
			if ($filter.GetType().Name -eq 'GroupsFilterData')
			{
				return @($group1, $group2);
			}			
		}
		Mock _GetItem {
			if ($Id -in @($enabledUser.Id, $disabledUser.Id))
			{
				# Always return a copy, so the state isn't actually changed between tests
				return $existingItems[$Id].PSObject.Copy();
			}

			if ($Id -in $existingItems.Keys)
			{
				return $existingItems[$Id];
			}
			
			throw "Item does not exist";
		}
		Mock _SaveItem {
			if ($IsNew)
			{
				$publicationId = 0;
				$itemType = $Item._ItemType;
				
				switch($itemType)
				{
					65552 {}
					65568 {}
					default { throw "Unexpected item type: $itemType"; }
				}

				$random = Get-Random -Minimum 10 -Maximum 500;
				$Item.Id ="tcm:$publicationId-$random-$itemType";
			}
			return $Item;
		}
		Mock _AddPublicationScope { 
			if ($Scope)
			{
				foreach ($publicationUri in $Scope)
				{
					$link = [PSCustomObject]@{ IdRef = $publicationUri };
					$Group.Scope += $link;
				}
			}
		}
		Mock _AddGroupMembership { 
			if (!$GroupUri) { return; }

			foreach($uri in @($GroupUri))
			{
				$groupData = [PSCustomObject]@{ Group = @{ IdRef = $uri}; }
				$Trustee.GroupMemberships += $groupData;
			}
			
		}
		Mock _ExpandPropertiesIfRequested { if ($ExpandProperties) { return $List | ForEach-Object { _GetItem $null $_.Id; } } else {return $List;} }
		Mock _IsExistingItem { return ($Id -in $existingItems.Keys); }			
		Mock _DeleteItem { if (!$Id -in $existingItems.Keys) { throw "Item does not exist." } }
		Mock Close-TridionCoreServiceClient {}
		Mock Get-TridionCoreServiceClient { return [PSCustomObject]@{}; }
		
		
		# ***********************
		# Tests
		# ***********************
		Context "Get-TridionUser" {
			It "validates input parameters" {
				{ Get-TridionUser -Id $null } | Should Throw;
				{ Get-TridionUser -Id '' } | Should Throw;
				{ Get-TridionUser -Id 'tcm:0-12-1' } | Should Throw;
			}
			
			It "disposes the client after use" {
				Get-TridionUser -Id $user1.Id | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports look-up by ID" {
				$user = Get-TridionUser -Id $user1.Id;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$user | Should Be $user1;
			}
			
			It "supports look-up by title" {
				$user = Get-TridionUser -Name $user1.Title;
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				$user | Should Be $user1;
			}

			It "supports look-up by custom filter" {
				$filter = { $_.Privileges -eq 1 };
				$user = Get-TridionUser -Filter $filter;
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				$user | Should Be $user1;
			}
			
			It "returns the current user" {
				$user = Get-TridionUser -Current;
				Assert-MockCalled _GetCurrentUser -Times 1 -Scope It;
				$user | Should Be $user1;
			}
			
			It "handles items that do not exist" {
				Get-TridionUser -Id 'tcm:0-99-65552' | Should Be $null;
				Get-TridionUser -Id 'tcm:0-0-0' | Should Be $null;
			}
			
			It "supports piping in the filter" {
				$Names = @({ $_.Title -eq $user1.Title}, {$_.Description -eq $user2.Description});
				$users = ($Names | Get-TridionUser);
				
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				
				$users.Count | Should Be 2;
				$users[0] | Should Be $user1;
				$users[1] | Should Be $user2;
			}
			
			It "supports piping in the filter as object" {
				$filter = { $_.Privileges -eq 1 };
				$user = ($filter | Get-TridionUser);
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				$user | Should Be $user1;
			}
			
			It "supports piping in the ID by property name" {
				$testInput = [PSCustomObject]@{ Id = $user1.Id };
				$user = ($testInput | Get-TridionUser);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $user1.Id };
				$user | Should Be $user1;
			}
			
			It "supports piping in the title by property name" {
				$testInput = [PSCustomObject]@{ Title = $user1.Title };
				$users = ($testInput | Get-TridionUser);
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				$users | Should Be $user1;
			}
			
			It "supports piping in the description by property name" {
				$testInput = [PSCustomObject]@{ Description = $user1.Description};
				$users = ($testInput | Get-TridionUser -Verbose);
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				
				$users | Should Be $user1;
			}
			
			It "supports expanding properties in list by name" {
				$user = (Get-TridionUser -Name $user1.Title -ExpandProperties);

				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				Assert-MockCalled _ExpandPropertiesIfRequested -Times 1 -Scope It -ParameterFilter { $ExpandProperties -eq $true };
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				
				$user | Should Be $user1;
			}
			
			It "supports expanding properties in list by description" {
				$user = (Get-TridionUser -Description $user1.Description -ExpandProperties);

				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				Assert-MockCalled _ExpandPropertiesIfRequested -Times 1 -Scope It -ParameterFilter { $ExpandProperties -eq $true };
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				
				$user | Should Be $user1;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$user = Get-TridionUser -Title $user1.Title;
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				$user | Should Be $user1;
			}

			It "has aliases for backwards-compatibility (Get-TridionUsers => Get-TridionUser)" {
				$alias = Get-Alias -Name Get-TridionUsers;
				$alias.Definition | Should Be 'Get-TridionUser';
				
				# Check that it also works as expected (i.e. gets a list of items)
				$users = Get-TridionUsers;
				Assert-MockCalled _GetTridionUsers -Times 1 -Scope It;
				$users | Should Be @($user1, $user2);
			}
		}

		Context "Get-TridionGroup" {
			It "validates input parameters" {
				{ Get-TridionGroup -Id $null } | Should Throw;
				{ Get-TridionGroup -Id '' } | Should Throw;
				{ Get-TridionGroup -Id 'tcm:0-12-1' } | Should Throw;
			}
			
			It "disposes the client after use" {
				Get-TridionGroup -Id $group1.Id | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
			}
			
			It "supports look-up by ID" {
				$group = Get-TridionGroup -Id $group1.Id;
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				$group | Should Be $group1;
			}
			
			It "supports look-up by title" {
				$group = Get-TridionGroup -Name $group1.Title;
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				$group | Should Be $group1;
			}

			It "supports look-up by custom filter" {
				$filter = { $_.ExtensionProperties['Custom'] -eq 'G1' };
				$group = Get-TridionGroup -Filter $filter;
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				$group | Should Be $group1;
			}
			
			It "handles items that do not exist" {
				Get-TridionGroup -Id 'tcm:0-99-65568' | Should Be $null;
				Get-TridionGroup -Id 'tcm:0-0-0' | Should Be $null;
			}
			
			It "supports piping in the filter" {
				$Names = @({ $_.Title -eq $group1.Title}, {$_.Description -eq $group2.Description});
				$groups = ($Names | Get-TridionGroup);
				
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				
				$groups.Count | Should Be 2;
				$groups[0] | Should Be $group1;
				$groups[1] | Should Be $group2;
			}
			
			It "supports piping in the filter as object" {
				$filter = { $_.ExtensionProperties['Custom'] -eq 'G1' };
				$group = ($filter | Get-TridionGroup);
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				$group | Should Be $group1;
			}
			
			It "supports piping in the ID by property name" {
				$testInput = [PSCustomObject]@{ Id = $group1.Id };
				$group = ($testInput | Get-TridionGroup);
				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $group1.Id };
				$group | Should Be $group1;
			}
			
			It "supports piping in the title by property name" {
				$testInput = [PSCustomObject]@{ Title = $group1.Title };
				$groups = ($testInput | Get-TridionGroup);
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				$groups | Should Be $group1;
			}
			
			It "supports piping in the description by property name" {
				$testInput = [PSCustomObject]@{ Description = $group1.Description};
				$groups = ($testInput | Get-TridionGroup -Verbose);
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				Assert-MockCalled _IsExistingItem -Times 0 -Scope It;
				Assert-MockCalled _GetItem -Times 0 -Scope It;
				
				$groups | Should Be $group1;
			}
			
			It "supports expanding properties in list by name" {
				$group = (Get-TridionGroup -Name $group1.Title -ExpandProperties);

				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				Assert-MockCalled _ExpandPropertiesIfRequested -Times 1 -Scope It -ParameterFilter { $ExpandProperties -eq $true };
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				
				$group | Should Be $group1;
			}
			
			It "supports expanding properties in list by description" {
				$group = (Get-TridionGroup -Description $group1.Description -ExpandProperties);

				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				Assert-MockCalled _ExpandPropertiesIfRequested -Times 1 -Scope It -ParameterFilter { $ExpandProperties -eq $true };
				Assert-MockCalled _GetItem -Times 1 -Scope It;
				
				$group | Should Be $group1;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$group = Get-TridionGroup -Title $group1.Title;
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				$group | Should Be $group1;
			}

			It "has aliases for backwards-compatibility (Get-TridionGroups => Get-TridionGroup)" {
				$alias = Get-Alias -Name Get-TridionGroups;
				$alias.Definition | Should Be 'Get-TridionGroup';
				
				# Check that it also works as expected (i.e. gets a list of items)
				$groups = Get-TridionGroups;
				Assert-MockCalled _GetTridionGroups -Times 1 -Scope It;
				$groups | Should Be @($group1, $group2);
			}
		}		

		Context "New-TridionGroup" {
			It "validates input parameters" {
				{ New-TridionGroup -Name $null } | Should Throw;
				{ New-TridionGroup -Name '' } | Should Throw;
			}
			
			It "disposes the client after use" {
				New-TridionGroup -Name 'Testing dispose' | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
			}
			
			It "returns the result" {
				$name = 'Testing';
				$description = 'Purely for testing purposes'
				$scope = @('tcm:0-1-1', 'tcm:0-2-1');
				$group = New-TridionGroup -Name $name -Description $description -Scope $scope;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				
				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $description;
				$group.Scope.Count | Should Be 2;
				$group.Scope[0].IdRef | Should Be $scope[0];
				$group.Scope[1].IdRef | Should Be $scope[1];
				$group.GroupMemberships.Count | Should Be 0;
			}

			It "supports piping in the name and description by property name" {
				$description = "Test Description";
				$testInput = [PSCustomObject]@{ Name = $group1.Title; Description = $description };
				$group = ($testInput | New-TridionGroup);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $testInput.Name;
				$group.Description | Should Be $testInput.Description;
				$group.Scope.Count | Should Be 0;
				$group.GroupMemberships.Count | Should Be 0;
			}

			It "supports piping in the scope by property name" {
				$name = 'Testing scope';
				$scope = @('tcm:0-1-1', 'tcm:0-2-1');
				$testInput = [PSCustomObject]@{ Scope = $scope };
				$group = ($testInput | New-TridionGroup -Name $name);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				Assert-MockCalled _AddPublicationScope -Times 1 -Scope It;
				Assert-MockCalled _AddGroupMembership -Times 1 -Scope It;

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $name;

				$group.Scope.Count | Should Be 2;
				$group.Scope[0].IdRef | Should Be $scope[0];
				$group.Scope[1].IdRef | Should Be $scope[1];
				$group.GroupMemberships.Count | Should Be 0;
			}

			It "supports single value scope" {
				$name = 'Testing single value scope';
				$group = New-TridionGroup -Name $name -Scope 'tcm:0-1-1';

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				Assert-MockCalled _AddPublicationScope -Times 1 -Scope It;
				Assert-MockCalled _AddGroupMembership -Times 1 -Scope It;

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $name;
				$group.Scope.Count | Should Be 1;
				$group.Scope[0].IdRef | Should Be 'tcm:0-1-1';
				$group.GroupMemberships.Count | Should Be 0;
			}

			It "supports piping in the group membership by property name" {
				$name = 'Testing group membership';
				$memberOf = @($group1.Id, $group2.Id);
				$testInput = [PSCustomObject]@{ MemberOf = $memberOf };
				$group = ($testInput | New-TridionGroup -Name $name);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				Assert-MockCalled _AddPublicationScope -Times 1 -Scope It;
				Assert-MockCalled _AddGroupMembership -Times 1 -Scope It;

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $name;
				$group.Scope.Count | Should Be 0;
				$group.GroupMemberships.Count | Should Be 2;
				$group.GroupMemberships[0].Group.IdRef | Should Be $memberOf[0];
				$group.GroupMemberships[1].Group.IdRef | Should Be $memberOf[1];
			}

			It "supports single group membership" {
				$name = 'Testing single value group membership';
				$group = New-TridionGroup -Name $name -MemberOf $group1.Id;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				Assert-MockCalled _AddPublicationScope -Times 1 -Scope It;
				Assert-MockCalled _AddGroupMembership -Times 1 -Scope It;

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $name;
				$group.Scope.Count | Should Be 0;
				$group.GroupMemberships.Count | Should Be 1;
				$group.GroupMemberships[0].Group.IdRef | Should Be $group1.Id;
			}
			
			It "defaults to the name as the description" {
				$name = 'Both Name and Description';
				$group = New-TridionGroup -Name $name;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				Assert-MockCalled _AddPublicationScope -Times 1 -Scope It;
				Assert-MockCalled _AddGroupMembership -Times 1 -Scope It;

				$group.Id | Should Not BeNullOrEmpty;
				$group.Id | Should Not Be 'tcm:0-0-0';
				$group.Title | Should Be $name;
				$group.Description | Should Be $name;
				$group.Scope.Count | Should Be 0;
				$group.GroupMemberships.Count | Should Be 0;
			}
			
			It "has aliases for backwards-compatibility (-Title => -Name)" {
				$group = New-TridionGroup -Title $group1.Title;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$group.Title | Should Be $group1.Title;
			}
		}

		Context "New-TridionUser" {
			It "validates input parameters" {
				{ New-TridionUser -Name $null } | Should Throw;
				{ New-TridionUser -Name '' } | Should Throw;
			}
			
			It "disposes the client after use" {
				New-TridionUser -Name 'Testing dispose' | Out-Null;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
			}
			
			It "returns the result" {
				$name = 'DOMAIN\username';
				$description = 'Test User'
				$user = New-TridionUser -Name $name -Description $description;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				
				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $description;
				$user.GroupMemberships.Count | Should Be 0;
				$user.Privileges | Should Be 0;
			}

			It "supports making the user an administrator" {
				$name = 'DOMAIN\username';
				$description = 'Test User'
				$user = New-TridionUser -Name $name -Description $description -MakeAdministrator;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				
				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $description;
				$user.GroupMemberships.Count | Should Be 0;
				$user.Privileges | Should Be 1;
			}

			It "supports piping in the name and description by property name" {
				$name = 'DOMAIN\username';
				$description = "Test User";
				$testInput = [PSCustomObject]@{ Name = $name; Description = $description };
				$user = ($testInput | New-TridionUser);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $testInput.Name;
				$user.Description | Should Be $testInput.Description;
				$user.GroupMemberships.Count | Should Be 0;
				$user.Privileges | Should Be 0;
			}

			It "supports piping in the group membership by property name" {
				$name = 'Testing group membership';
				$memberOf = @($group1.Id, $group2.Id);
				$testInput = [PSCustomObject]@{ MemberOf = $memberOf };
				$user = ($testInput | New-TridionUser -Name $name);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $name;
				$user.GroupMemberships.Count | Should Be 2;
				$user.GroupMemberships[0].Group.IdRef | Should Be $memberOf[0];
				$user.GroupMemberships[1].Group.IdRef | Should Be $memberOf[1];
				$user.Privileges | Should Be 0;
			}

			It "supports single group membership" {
				$name = 'Testing single value group membership';
				$user = New-TridionUser -Name $name -MemberOf $group1.Id;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $name;
				$user.GroupMemberships.Count | Should Be 1;
				$user.GroupMemberships[0].Group.IdRef | Should Be $group1.Id;
				$user.Privileges | Should Be 0;
			}
			
			It "supports look-up by titles in group memberships" {
				$name = 'Testing group membership by title';
				$memberOf = @($group1.Title, $group2.Title);
				$testInput = [PSCustomObject]@{ MemberOf = $memberOf };
				$user = ($testInput | New-TridionUser -Name $name);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $name;
				$user.GroupMemberships.Count | Should Be 2;
				$user.GroupMemberships[0].Group.IdRef | Should Be $group1.Id;
				$user.GroupMemberships[1].Group.IdRef | Should Be $group2.Id;
				$user.Privileges | Should Be 0;
			}

			It "defaults to the name as the description" {
				$name = 'DOMAIN\username';
				$user = New-TridionUser -Name $name;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };

				$user.Id | Should Not BeNullOrEmpty;
				$user.Id | Should Not Be 'tcm:0-0-0';
				$user.Title | Should Be $name;
				$user.Description | Should Be $name;
				$user.GroupMemberships.Count | Should Be 0;
				$user.Privileges | Should Be 0;
			}
			
			It "has aliases for backwards-compatibility (-UserName => -Name)" {
				$name = 'DOMAIN\username';
				$user = New-TridionUser -UserName $name;

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $true };
				
				$user.Title | Should Be $name;
			}
		}

		Context "Disable-TridionUser" {
			It "validates input parameters" {
				{ Disable-TridionUser -Id $null } | Should Throw;
				{ Disable-TridionUser -Id 'tcm:0-12-1' } | Should Throw;

				{ Disable-TridionUser -Id '' } | Should Not Throw;
				{ Disable-TridionUser -Id 'tcm:0-0-0' } | Should Not Throw;
			}
			
			It "disposes the client after use" {
				Disable-TridionUser -Id $enabledUser.Id;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };
			}
			
			It "supports passthru to return the result" {
				$enabledUser.IsEnabled | Should Be $true;
				$user = Disable-TridionUser -Id $enabledUser.Id -PassThru;

				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $enabledUser.Id };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };
				
				$user.IsEnabled | Should Be $false;
			}

			It "supports piping in the user" {
				$testInput = $enabledUser.PSObject.Copy();
				$testInput.IsEnabled | Should Be $true;
				$user = ($testInput | Disable-TridionUser -PassThru);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };

				$user.IsEnabled | Should Be $false;
			}

			It "supports piping in the Id by property name" {
				$testInput = [PSCustomObject]@{ Id = $enabledUser.Id };
				$user = ($testInput | Disable-TridionUser -PassThru);

				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $enabledUser.Id };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };

				$user.IsEnabled | Should Be $false;
			}
		}		
	

		Context "Enable-TridionUser" {
			It "validates input parameters" {
				{ Enable-TridionUser -Id $null } | Should Throw;
				{ Enable-TridionUser -Id '' } | Should Throw;
				{ Enable-TridionUser -Id 'tcm:0-12-1' } | Should Throw;

				{ Enable-TridionUser -Id 'tcm:0-0-0' } | Should Not Throw;
			}
			
			It "disposes the client after use" {
				Enable-TridionUser -Id $disabledUser.Id;
				Assert-MockCalled Close-TridionCoreServiceClient -Times 1 -Scope It;
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };
			}
			
			It "supports passthru to return the result" {
				$user = Enable-TridionUser -Id $disabledUser.Id -PassThru;

				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $disabledUser.Id };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };
				
				$user.IsEnabled | Should Be $true;
			}

			It "supports piping in the user" {
				$testInput = $disabledUser.PSObject.Copy();
				$testInput.IsEnabled | Should Be $false;
				$user = ($testInput | Enable-TridionUser -PassThru);

				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };

				$user.IsEnabled | Should Be $true;
			}

			It "supports piping in the Id by property name" {
				$testInput = [PSCustomObject]@{ Id = $disabledUser.Id };
				$user = ($testInput | Enable-TridionUser -PassThru);

				Assert-MockCalled _GetItem -Times 1 -Scope It -ParameterFilter { $Id -eq $disabledUser.Id };
				Assert-MockCalled _SaveItem -Times 1 -Scope It -ParameterFilter { $IsNew -eq $false };

				$user.IsEnabled | Should Be $true;
			}
		}		
	}
}