# -ParameterFilter { $Name -eq "World" }
# You never declared $Name. Where does it come from?

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
        foreach ($call in $script:calls) {
            # inject bound params into the CALLER's script scope
            # — that's where $ParameterFilter is probably bound.
            foreach ($p in $call.GetEnumerator()) {
                # $PSCmdlet.SessionState.PSVariable.Set($p.Key, $p.Value)
            }
            if (& $ParameterFilter) {
                "matched: Name=$($call.Name)"
            }
        }
    }

    Export-ModuleMember -Function Get-Greeting, Verify
} | Import-Module

Get-Greeting -Name World

$expected = "World"
Verify -ParameterFilter { 
    Set-StrictMode -Version Latest
    $Name -eq $expected
}

# cleanup
Get-Module Greeter | Remove-Module
Remove-Variable -Name expected -ErrorAction SilentlyContinue
Remove-Variable -Name Name -ErrorAction SilentlyContinue
