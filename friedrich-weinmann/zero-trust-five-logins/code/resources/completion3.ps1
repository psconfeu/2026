. "$PSScriptRoot\Get-ZtTestMetadata.ps1"

function Invoke-Test {
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('ZtTest3')]
		[string]
		$Test
	)

	$Test
}
Register-PSFTeppScriptblock -Name 'ZtTest3' -ScriptBlock {
	Get-ZtTestMetadata -Path 'C:\Code\github\zerotrustassessment\src\powershell\tests\Test-Assessment.*.ps1' | Where-Object Pillar | ForEach-Object {
		@{
			Text = $_.TestID
			Tooltip = "{0} | {1} | {2}`n{3}" -f $_.Pillar, $_.Service, $_.Category, $_.Title
		}
	}
} -CacheDuration 2h