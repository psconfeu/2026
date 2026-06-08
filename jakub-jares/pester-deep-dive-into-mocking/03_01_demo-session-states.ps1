# Modules are silos — each has its own variables and functions.
Get-Module Greeter | Remove-Module
New-Module -Name Greeter -ScriptBlock {
    function Get-Greeting { "Hello" }
    function Get-Message { "$(Get-Greeting), World!" }
    Export-ModuleMember -Function Get-Message
} | Import-Module

Get-Message # "Hello, World!"

# Grab PSModuleInfo,
# inject a function into the module, replacing the internal one.
. (Get-Module Greeter) {
    function Get-Greeting { "Ahoy" }
}

Get-Message # "Ahoy, World!"

Get-Module Greeter | Remove-Module
