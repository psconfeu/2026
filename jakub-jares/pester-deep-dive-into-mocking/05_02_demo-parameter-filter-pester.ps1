# How Pester does it — Mock.ps1:1164 Test-ParameterFilter
# fixes 05_01: filter runs in caller's scope, variables don't leak

# Pester.Scoping.ps1:1 — reflection-rebind a scriptblock to a chosen session state
function Set-ScriptBlockScope {
    param(
        [scriptblock]$ScriptBlock, 
        [System.Management.Automation.SessionState]$SessionState)
    $flags = [Reflection.BindingFlags]'Instance,NonPublic'
    $internal = [System.Management.Automation.SessionState].GetProperty(
        'Internal', $flags).GetValue($SessionState, $null)
    [scriptblock].GetProperty('SessionStateInternal', $flags).SetValue(
        $ScriptBlock, $internal, $null)
}

New-Module -Name Greeter -ScriptBlock {
    $script:calls = [Collections.Generic.List[hashtable]]::new()

    function Get-Greeting {
        param([string]$Name)
        $script:calls.Add(@{ Name = $Name })
        "Hello, $Name!"
    }

    function Verify {
        [CmdletBinding()]
        param([scriptblock]$ParameterFilter)

        # Mock.ps1:1197 — the wrapper
        $wrapper = {
            param ($private:______mock_parameters)
            & $private:______mock_parameters.Set_StrictMode -Off

            foreach (
                $private:______current 
                in $private:______mock_parameters.Context.GetEnumerator()
            ) {

                $private:______mock_parameters.SessionState.PSVariable.Set(
                    $private:______current.Key,
                    $private:______current.Value
                )
            }

            $PesterBoundParameters = $private:______mock_parameters.Context
            $______isInMockParameterFilter = $true

            & $private:______mock_parameters.ScriptBlock
        }

        # Mock.ps1:1225 — rebind wrapper to the CALLER's session state
        # injected vars land in wrapper's child scope of caller -> auto-cleanup
        Set-ScriptBlockScope -ScriptBlock $wrapper -SessionState `
            $PSCmdlet.SessionState

        foreach ($call in $script:calls) {
            $passed = & $wrapper @{
                Context        = $call
                SessionState   = $PSCmdlet.SessionState
                ScriptBlock    = $ParameterFilter
                Set_StrictMode = Get-Command Set-StrictMode
            }
            if ($passed) {
                "matched: Name=$($call.Name)"
            }
        }
    }

    Export-ModuleMember -Function Get-Greeting, Verify
} | Import-Module

Get-Greeting -Name World

$expected = "World"
Verify -ParameterFilter { Set-StrictMode -Version Latest; $Name -eq $expected }

# no leak this time
"after Verify, `$Name = '$(Get-Variable Name -ValueOnly -ErrorAction SilentlyContinue)'"

# cleanup
Get-Module Greeter | Remove-Module
Remove-Item Function:\Set-ScriptBlockScope -Force
Remove-Variable -Name expected -ErrorAction SilentlyContinue
