function NeverGonnaMoveYou {
    ("NO! I WON'T!", "NAH, STAY HERE.", "YOU WISH!", "LOL, NOPE.") 
    | Get-Random
}

Set-Alias -Name Set-Location -Value NeverGonnaMoveYou -Scope Script

Set-Location C:\Windows

# aliases chain, and happily call other aliases.
cd C:\Windows # or chdir, or sl
 
# but also
Microsoft.PowerShell.Management\Set-Location C:\Windows

Set-Alias -Name Microsoft.PowerShell.Management\Set-Location `
    -Value NeverGonnaMoveYou -Scope Script

# cleanup
Remove-Item Alias:\Set-Location -Force
Remove-Item Alias:\Microsoft.PowerShell.Management\Set-Location -Force
