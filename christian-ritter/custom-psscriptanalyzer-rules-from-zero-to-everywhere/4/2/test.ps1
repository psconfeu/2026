$code = @'
<#
.SYNOPSIS
    This is a sample function.

.EXAMPLE
    SampleFunction -Name "John"
    This will output "Hello, John!"

.EXAMPLE
    SampleFunction -Name "Jane"
    This will output "Hello, Jane!"
#>
function SampleFunction {
    param(
        [string]$Name
    )

    Write-Output "Hello, $Name!"
}
'@

$tokens = $null
$errors = $null

$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $code,
    [ref]$tokens,
    [ref]$errors
)

$func = $ast.Find({
    param($node)

    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

$help = $func.GetHelpContent()

$help.Examples[2] -match "SampleFunction "