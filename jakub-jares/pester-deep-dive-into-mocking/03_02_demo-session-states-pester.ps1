# How Pester does it — reflection to rebind scriptblocks across session states.
# Pester.Runtime.ps1:50-53 — property setup
# Pester.Scoping.ps1 — Set-ScriptBlockScope

Get-Module Greeter | Remove-Module
New-Module -Name Greeter -ScriptBlock {
    function Get-Greeting { "Hello" }
    function Get-Message { "$(Get-Greeting), World!" }
    Export-ModuleMember -Function Get-Message
} | Import-Module

Get-Message # "Hello, World!"

# the scriptblock we want to run inside Greeter's session state
$sb = { function Get-Greeting { "Ahoy" } }

# Now we need to bind it to the module session state
# $moduleSessionState = (Get-Module Greeter).SessionState.Internal
# $sb.SessionStateInternal = $moduleSessionState

# get Greeter's session state — Pester.Scoping.ps1:16-17
$targetSessionState = & (Get-Module Greeter) { 
    $ExecutionContext.SessionState 
}

# Pester.Runtime.ps1:50-53
$flags = [Reflection.BindingFlags]'Instance,NonPublic'
$SessionStateInternalProperty = [System.Management.Automation.SessionState].GetProperty(
    'Internal', $flags)
$ScriptBlockSessionStateInternalProperty = [scriptblock].GetProperty(
    'SessionStateInternal', $flags)

# get Greeter's session state internal — Pester.Scoping.ps1:17-18
$targetInternal = $SessionStateInternalProperty.GetValue(
    $targetSessionState, $null)

# rebind the scriptblock — Pester.Scoping.ps1:43
$ScriptBlockSessionStateInternalProperty.SetValue(
    $sb, $targetInternal, $null)

. $sb

Get-Message # "Ahoy, World!"

Get-Module Greeter | Remove-Module
