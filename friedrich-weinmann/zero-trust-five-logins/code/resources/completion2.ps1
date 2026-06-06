. "$PSScriptRoot\Get-ZtTestMetadata.ps1"

function Invoke-Test {
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('ZtTest2')]
		[string]
		$Test
	)

	$Test
}
Register-PSFTeppScriptblock -Name 'ZtTest2' -ScriptBlock {
	(Get-ZtTestMetadata -Path 'C:\Code\github\zerotrustassessment\src\powershell\tests\Test-Assessment.*.ps1' | Where-Object Pillar).TestId
} -CacheDuration 2h