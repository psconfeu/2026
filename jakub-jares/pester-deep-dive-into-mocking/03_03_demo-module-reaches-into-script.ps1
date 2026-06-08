# The opposite: a module reaches into YOUR scope.

function Get-Greeting { "Hello" }
function Get-Message { "$(Get-Greeting), World!" }

Get-Message  # "Hello, World!"

# Need to call: 
# $targetSessionState = & (Get-Module "script session state") { 
#    $ExecutionContext.SessionState 
# }

New-Module -Name Sneaky -ScriptBlock {
    function Mock {
        [CmdletBinding()]
        param($CommandName, [scriptblock]$MockWith)

        # $PSCmdlet.SessionState — the CALLER's session state, not the module's
        $callerState = $PSCmdlet.SessionState

        $sb = [scriptblock]::Create(
            "function script:$CommandName { 
            $($MockWith.ToString()) }"
            )

        # rebind the scriptblock to run in the caller's world
        $flags = [Reflection.BindingFlags]'Instance,NonPublic'
        $internal = [System.Management.Automation.SessionState].GetProperty(
            'Internal', $flags).GetValue($callerState, $null)
        [scriptblock].GetProperty('SessionStateInternal', $flags).SetValue(
            $sb, $internal, $null)

        . $sb
    }

    Export-ModuleMember -Function Mock
} | Import-Module

Mock -CommandName Get-Greeting -MockWith { "Ahoy" }

Get-Message  # "Ahoy, World!"

# cleanup
Remove-Item Function:\Get-Greeting -Force
Remove-Item Function:\Get-Message -Force
Get-Module Sneaky | Remove-Module
