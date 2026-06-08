# Same thing, but how Pester actually does it (Mock.ps1)

# Mock.ps1:204 — unique name so it can't collide with anything
$mockName = "PesterMock_script_Set-Location_$([Guid]::NewGuid().Guid)"

# Mock.ps1:255 — define the function via the provider API
@($ExecutionContext.InvokeProvider.Item.Set("Function:\script:$mockName", {
    ("NO! I WON'T!", "NAH, STAY HERE.", "YOU WISH!", "LOL, NOPE.") | Get-Random
}, <# force: #> $true, <# passThru: #> $true))[0]

# Mock.ps1:258-261 — alias every name that resolves to the command
$command = Get-Command Set-Location
& (Get-Command Set-Alias) -Name $command.Name -Value $mockName -Scope Script
& (Get-Command Set-Alias) -Name "$($command.ModuleName)\$($command.Name)" `
    -Value $mockName -Scope Script -Force

Set-Location C:\Windows
cd C:\Windows
sl C:\Windows
Microsoft.PowerShell.Management\Set-Location C:\Windows

Remove-Item "Alias:\Set-Location" -Force
Remove-Item "Alias:\Microsoft.PowerShell.Management\Set-Location" -Force
Remove-Item "Function:\$mockName" -Force
