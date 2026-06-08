<#
.SYNOPSIS
Detects outdated PSConfeu greeting commands and suggests updating to the current year.
#>

function Measure-PSConfeu2025Greeting {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    process {
        try {

            [ScriptBlock]$predicate = {
                param([System.Management.Automation.Language.Ast]$Ast)

                if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                    return $Ast.GetCommandName() -match '^Greet-PSCONFEU\d{4}$' -and $AST.GetCommandName() -ne "Greet-PSCONFEU$((Get-Date).Year)"
                }

                return $false
            }

            $matches = $ScriptBlockAst.FindAll($predicate, $true)

            $results = @{}

            foreach ($ast in $matches) {

                $year = (Get-Date).Year
                $replacement = "Greet-PSCONFEU$year"

                # region extent values
                [int]$startLineNumber   = $ast.Extent.StartLineNumber
                [int]$endLineNumber     = $ast.Extent.EndLineNumber
                [int]$startColumnNumber = $ast.Extent.StartColumnNumber
                [int]$endColumnNumber   = $ast.Extent.EndColumnNumber
                # endregion

                # region fix text
                [string]$correction = $replacement
                [string]$file = $MyInvocation.MyCommand.Definition
                [string]$optionalDescription = "Update greeting command to current year ($year)"
                # endregion

                # region CorrectionExtent object
                $objParams = @{
                    TypeName     = 'Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent'
                    ArgumentList = $startLineNumber,
                                   $endLineNumber,
                                   $startColumnNumber,
                                   $endColumnNumber,
                                   $correction,
                                   $file,
                                   $optionalDescription
                }

                $correctionExtent = New-Object @objParams
                # endregion

                # region suggested corrections collection
                $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$($objParams.TypeName)]
                $suggestedCorrections.add($correctionExtent) | Out-Null # endregion

                # region diagnostic record
                $results[$ast.Extent] =
                    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message              = "Outdated greeting command detected. Use $replacement instead."
                        Extent               = $ast.Extent
                        RuleName             = $PSCmdlet.MyInvocation.InvocationName
                        Severity             = "Warning"
                        RuleSuppressionID    = "1338" # One step ahead of the average nerd, for sure.
                        SuggestedCorrections = $suggestedCorrections
                    }
                # endregion
            }

            return $results.Values
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Measure-PSConfeu2025Greeting