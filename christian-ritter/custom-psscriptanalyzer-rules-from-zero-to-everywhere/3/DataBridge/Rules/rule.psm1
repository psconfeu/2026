function Measure-DataBridgeUsage {
    param(
        [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
    )

    # Ensure we got a valid AST
    if ($null -eq $ScriptBlockAst) { return @() }

    $results = @()

    # Walk the AST recursively
    $ScriptBlockAst.FindAll({
        param($ast)

        # Only care about command AST nodes
        if ($ast -is [System.Management.Automation.Language.CommandAst] -and
            $ast.CommandElements.Count -gt 0) {

            $commandName = $ast.GetCommandName()

            if ($commandName -eq 'Invoke-DataBridge') {

                # Guard: make sure there is at least one argument or named parameter
                if ($ast.CommandElements.Count -le 1) { return }

                $first = $ast.CommandElements[1]
                $value = $null

                # Case 1: positional string argument
                if ($first -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $value = $first.Value
                }
                # Case 2: named parameter (-Data 'WhatSoEver')
                elseif ($first -is [System.Management.Automation.Language.CommandParameterAst] -and
                        $ast.CommandElements.Count -gt 2) {

                    $second = $ast.CommandElements[2]

                    $value = switch ($second) {
                        { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] } { $_.Value }
                        { $_ -is [System.Management.Automation.Language.VariableExpressionAst] } { $_.VariablePath.UserPath }
                        default { $_.Extent.Text }
                    }
                }
                # Case 3: fallback for any other AST type
                else {
                    $value = $first.Extent.Text
                }

                # Update global DataBridge only if different
                if ([DataBridge]::Bridge -ne $value) {
                    [DataBridge]::Bridge = $value
                }

                # Add to results array
                $results += [pscustomobject]@{
                    Command = $commandName
                    Value   = [DataBridge]::Bridge
                    Line    = $ast.Extent.StartLineNumber
                }
            }
        }

    }, $true)

    return $results
}
