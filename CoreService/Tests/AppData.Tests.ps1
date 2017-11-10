#Requires -version 3.0
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

<#
**************************************************
* Helper functions
**************************************************
#>
<#
**************************************************
* Tests
**************************************************
#>

Describe "Core Service AppData Tests" {
	BeforeAll {
		$parent = Split-Path -Parent $here
		
		Get-Module Tridion-CoreService | Remove-Module
		$modulesToImport = @('Tridion-CoreService.psd1', 'AppData.psm1');
		$modulesToImport | ForEach-Object { Import-Module (Join-Path $parent $_) -Force; }
	}

	Context "Convert-TridionApplicationData" {
		InModuleScope AppData {
			# ***********************
			# Mocks
			# ***********************
			
			# ***********************
			# Tests
			# ***********************
			It "validates input parameters" {
				{ Convert-TridionApplicationData -ApplicationData $null } | Should Throw;
				{ Convert-TridionApplicationData -ApplicationData '' } | Should Throw;
			}

			It "returns null when given no data" {
				$appData = @{
					Data = $null;
					TypeId = $null;
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $null;
			}

			It "handles c:XmlDocument type (Unicode encoding)" {
				$data = '<root><subElement>ァ ア ィ イ ゥ ウ ェ エ ォ オ</subElement></root>';
				
				$encoding = [system.Text.Encoding]::Unicode;
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = 'c:XmlDocument';
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $data;
			}

			It "handles XmlDocument type (UTF-8 encoding)" {
				$data = '<root><subElement>ァ ア ィ イ ゥ ウ ェ エ ォ オ</subElement></root>';
				
				$encoding = [system.Text.Encoding]::UTF8;
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = 'XmlDocument';
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $data;
			}

			It "handles XmlElement type (UTF-8 encoding)" {
				$data = '<root><subElement>ァ ア ィ イ ゥ ウ ェ エ ォ オ</subElement></root>';
				
				$encoding = [system.Text.Encoding]::UTF8;
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = 'XmlElement';
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $data;
			}

			It "handles image type (ISO-8859-1 encoding)" {
				$data = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXR...';
				
				$encoding = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = 'image/png';
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $data;
			}

			It "defaults to UTF-8 encoding" {
				$data = '<root><subElement>ァ ア ィ イ ゥ ウ ェ エ ォ オ</subElement></root>';
				
				$encoding = [system.Text.Encoding]::UTF8;
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = '';
				}

				$result = Convert-TridionApplicationData -ApplicationData $appData;
				$result | Should Be $data;
			}

			It "supports data from pipeline" {
				$data = '<root><subElement>ァ ア ィ イ ゥ ウ ェ エ ォ オ</subElement></root>';
				
				$encoding = [system.Text.Encoding]::UTF8;
				$bytes = $encoding.GetBytes($data);

				$appData = @{
					Data = $bytes;
					TypeId = '';
				}

				$result = ($appData | Convert-TridionApplicationData);
				$result | Should Be $data;
			}
		}
	}	
	
	Context "Get-TridionApplicationData" {
		InModuleScope AppData {
			# ***********************
			# Mocks
			# ***********************
			
			# ***********************
			# Tests
			# ***********************
		}
	}	
	
	Context "Set-TridionApplicationData" {
		InModuleScope AppData {
			# ***********************
			# Mocks
			# ***********************
			
			# ***********************
			# Tests
			# ***********************
		}
	}	
	
	Context "Remove-TridionApplicationData" {
		InModuleScope AppData {
			# ***********************
			# Mocks
			# ***********************
			
			# ***********************
			# Tests
			# ***********************
		}
	}	
}