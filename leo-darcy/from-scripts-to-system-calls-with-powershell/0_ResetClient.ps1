If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Throw "This Presentation must be run as admin"
}
Else
{ 
    Write-Output "Running as admin"
}

Get-VpnConnection -AllUserConnection | Format-Table
