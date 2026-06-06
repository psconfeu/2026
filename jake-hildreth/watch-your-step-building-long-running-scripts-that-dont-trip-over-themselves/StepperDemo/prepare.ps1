Get-ChildItem "$PSScriptRoot/private/*.ps1" | ForEach-Object { . $_.FullName }
brew install mono-libgdiplus
Install-Module -Name Stepper -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser
