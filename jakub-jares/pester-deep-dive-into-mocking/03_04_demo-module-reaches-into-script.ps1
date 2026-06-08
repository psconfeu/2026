# The opposite: a module reaches into the caller's script scope
# and defines a mock function + alias there.
# This is what Pester does when you call Mock without -ModuleName.

# a function we want to mock, lives in script scope
function Get-Greeting { "Hello" }
function Get-Message { "$(Get-Greeting), World!" }

Get-Message # "Hello, World!"

# PesterLite module — defines Mock command
New-Module -Name PesterLite -ScriptBlock {
    $flags = [Reflection.BindingFlags]'Instance,NonPublic'
    $SessionStateInternalProperty = [System.Management.Automation.SessionState].GetProperty(
        'Internal', $flags)
    $ScriptBlockSessionStateInternalProperty = [scriptblock].GetProperty(
        'SessionStateInternal', $flags)

    function Mock {
        [CmdletBinding()]
        param($CommandName, [scriptblock]$MockWith)

        # Pester.SessionState.Mock.ps1:238
        $callerSessionState = $PSCmdlet.SessionState
        $callerInternal = $SessionStateInternalProperty.GetValue(
            $callerSessionState, $null)

        $mockName = "PesterMock_script_${CommandName}_$([Guid]::NewGuid().Guid)"

        $sb = [scriptblock]::Create("
            function script:$mockName { $($MockWith.ToString()) }
            Set-Alias -Name $CommandName -Value $mockName -Scope Script
        ")

        $ScriptBlockSessionStateInternalProperty.SetValue($sb, $callerInternal, $null)
        . $sb
    }

    Export-ModuleMember -Function Mock
} | Import-Module

Mock -CommandName Get-Greeting -MockWith { "Ahoy" }

Get-Message # "Ahoy, World!"

# cleanup
Remove-Item Alias:\Get-Greeting -Force
Get-Item Function:\PesterMock_* | Remove-Item -Force
Get-Module PesterLite | Remove-Module
