function Measure-PSConfeu2025Greeting {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )
    Process {
        try {
                #region Define predicates to find ASTs.
                [ScriptBlock]$predicate1 = {
                    param ([System.Management.Automation.Language.Ast]$Ast)

                    if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
                        # Extract the command name safely
                        $commandName = $Ast.GetCommandName()

                        if ($commandName -eq 'Greet-PSConfeu2025') {
                            return $true
                        }
                    }

                    return $false
                }

                #endregion

            #region Finds ASTs that match the predicate.

            [System.Management.Automation.Language.Ast[]]$methodAst = $ScriptBlockAst.FindAll($predicate1, $true)

            $ResultHT = @{}
            $methodAst | ForEach-Object {
                $ResultHT[$_.Extent] = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{

                    "Message"               = "Found a call to Greet-PSConfeu2025. Check for current year and update if necessary."
                    "Extent"                = $_.Extent
                    "RuleName"              = $PSCmdlet.MyInvocation.InvocationName
                    "Severity"              = "Warning"
                    "RuleSuppressionID"     = "1337" # Very creative, for sure.
                }
            }
            return $resultHT.Values

            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
Export-ModuleMember -Function Measure-PSConfeu2025Greeting