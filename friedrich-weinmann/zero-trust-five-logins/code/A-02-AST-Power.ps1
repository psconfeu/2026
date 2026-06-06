# Failsafe
return

#----------------------------------------------------------------------------#
#                     Climbing the Abstract Syntax Tree                      #
#----------------------------------------------------------------------------#

$resourcePath = 'C:\Code\github\P2026-PSConfEU-ZeroTrustAssessment\code\resources'

# Old
code "$resourcePath\TestMeta.json"

# New
code "$resourcePath\Test-Assessment.21770.ps1"

$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile("$resourcePath\Test-Assessment.21770.ps1", [ref]$tokens, [ref]$errors)

$ast
$ast.EndBlock.Statements[0]
$ast.EndBlock.Statements[0].GetType()
$ast.EndBlock.Statements[0].Body.ParamBlock.Attributes
$ast.EndBlock.Statements[0].Body.ParamBlock.Attributes.Where{$_.TypeName.FullName -eq 'ZtTest' }.NamedArguments

$data = @{}
foreach ($namedArg in $ast.EndBlock.Statements[0].Body.ParamBlock.Attributes.Where{$_.TypeName.FullName -eq 'ZtTest' }.NamedArguments) {
	$data[$namedArg.ArgumentName] = $namedArg.Argument.SafeGetValue()
}
[pscustomobject]$data

code "$resourcePath\Get-ZtTestMetadata.ps1"
. "$resourcePath\Get-ZtTestMetadata.ps1"
Get-ZtTestMetadata -Path 'C:\Code\github\zerotrustassessment\src\powershell\tests\Test-Assessment.*.ps1'

# Tools:
# Module: Refactor
# https://github.com/FriedrichWeinmann/Refactor

#-> Next: Running Away
code "$presentatioNRoot\A-03-RunspaceWorkflows.ps1"