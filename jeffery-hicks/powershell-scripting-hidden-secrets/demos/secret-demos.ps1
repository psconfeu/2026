#requires -version 7.6

Return "This is a demo script file"

#region Console Cheats

#region PSReadline Key Handlers

#Demo these in a console session.
#There could be conflicts with VSCode keybindings

#many defaults
#shows bound by default
Get-PSReadLineKeyHandler
Get-PSReadLineKeyHandler -Unbound | more

#add handlers for PSReadline functions
#put cursor on first letter of the word

#use ENTER to copy
Set-PSReadLineKeyHandler -key F12 -Function CaptureScreen

#create your own action
Set-PSReadLineKeyHandler -key Ctrl+h -BriefDescription 'Open PSReadLineHistory' -Description "View PSReadLine history file with the associated application." -ScriptBlock {
    #open the history file with the associated application for .txt files, probably Notepad.
    Invoke-Item -Path $(Get-PSReadLineOption).HistorySavePath
}

Set-PSReadLineKeyHandler -Key Shift+F1 -BriefDescription OnlineCommandHelp -LongDescription "Open online help for the current command. [$($env:username)]" -ScriptBlock {
    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
            $node = $args[0]
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null) {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null) {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [System.Management.Automation.AliasInfo]) {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null) {
                Get-Help $commandName -Online
            }
        }
    }
}
#directory jumping

$global:PSReadlineMarks = @{
    [char]'s' = "C:\scripts"
    [char]'t' = "c:\temp"
    [char]'w' = "c:\work"
}

Set-PSReadLineKeyHandler -Key Ctrl+j -BriefDescription JumpDirectory -LongDescription "Goto the marked directory." -ScriptBlock {
    $key = [Console]::ReadKey()
    $dir = $global:PSReadLineMarks[$key.KeyChar]
    if ($dir) {
        Set-Location $dir
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}
Set-PSReadLineKeyHandler -Key Ctrl+Alt+j -BriefDescription MarkDirectory -LongDescription "Mark the current directory." -ScriptBlock {
    #press a single character to mark the current directory
    $key = [Console]::ReadKey($true)
    if ($key.KeyChar -match '\w') {
        $global:PSReadLineMarks[$key.KeyChar] = $pwd
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
        Write-Warning 'You entered an invalid character.'
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

#show the list
Set-PSReadLineKeyHandler -Key Alt+j -BriefDescription ShowDirectoryMarks -LongDescription "Show the currently marked directories. [$($env:username)]" -ScriptBlock {
    $data = $global:PSReadLineMarks.GetEnumerator() | Where-Object { $_.key } | Sort-Object key
    $data | ForEach-Object -Begin {
        $text = @"
Key`tDirectory
---`t---------

"@
    } -Process {

        $text += "{0}`t{1}`n" -f $_.key, $_.value
    }

    if ($PSedition -eq 'Desktop' -or $IsWindows) {
        $ws = New-Object -ComObject WScript.Shell
        [void]$ws.popup($text, 10, 'Use Ctrl+J to jump')
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
    else {
        Write-Host "`n$text`n" -ForegroundColor Yellow
    }
}

#list keys in use
Get-PSReadLineKeyHandler -bound | Select-Object Key | Sort-Object Key |
Format-Wide -Column 4

#list my key handlers
$sb = {
    Get-PSReadLineKeyHandler | where group -EQ custom |
    Select-Object Key,Function,Description |
    Out-GridView -Title "My custom key handlers"
}

Set-PSReadLineKeyHandler -key "Alt+k" -BriefDescription "ListMyHandlers" -Description "List my PSReadLine KeyHandlers" -ScriptBlock $sb

#can't write output to the current session

help Remove-PSReadLineKeyHandler
#endregion

#region Windows Terminal key handlers
#these will apply to all profiles

#use command palette
# uptime

#Settings - Actions
#edit your settings JSON file
#Windows terminal will add the ID
#add \r to run it

psedit .\settings-excerpt.json

#add key handler

#added a key handler

#Go to Key bindings
#use the ID property

#watch your quotes and JSON escaping

#restart Windows Terminal
Get-PSReadLineKeyHandler | where group -EQ custom |
Select-Object Key,Function,Description |
Format-SpectreTable -Title "My custom key handlers" -color Chartreuse1 |
Out-SpectreHost

#endregion

#region Windows Terminal Scratch Pad
#scratch pad (ctrl+alt+;) split ctrl+alt+o  ctrl+shift+W to close

#If splitting, you will need to close the entire tab to get rid of the scratch pad. The
#shortcut will crash the app.

#endregion

#endregion console cheat

#region Scripting Surprises

#region [System.Diagnostics.Stopwatch]

$sw = [System.Diagnostics.Stopwatch]::new()
$sw
$sw.start()
$sw
$sw.Stop()
$sw.Elapsed

#I use this in verbose output
# https://github.com/jdhitsolutions/PSWorkItem

$w = Get-PSWorkItem -all -Verbose
https://github.com/jdhitsolutions/PSWorkItem/tree/main/functions
#psedit C:\scripts\PSWorkItem\functions\private\helpers.ps1
#psedit C:\scripts\PSWorkItem\functions\public\Get-PSWorkItem.ps1

#endregion

#region Join-String
help Join-String

"don","jason","jeff" | Join-String
"don","jason","jeff" | Join-String -Separator "|"
"don","jason","jeff" | Join-String -Separator "|" -SingleQuote

#create a string with code
$rx = Get-ChildItem -file | Group-Object extension -NoElement |
Join-String -Property Name -Separator "|" -OutputPrefix "(" -OutputSuffix ")$"

$rx
dir c:\temp -file -Recurse | where {$_.fullname -notmatch $rx}

#endregion

#region FormatHyperLink

$PSStyle | Get-Member -MemberType method

#Windows terminal already creates links
Write-Host "Learn more at https://Microsoft.com/powershell" -ForegroundColor Yellow

#create a sample link
$PSStyle.FormatHyperlink.OverloadDefinitions

$link = $PSStyle.FormatHyperlink("$($PSStyle.Italic)Microsoft Learning$($PSStyle.ItalicOff)","https://microsoft.com/powershell")

$m =  "{0}Learn more at {1}{2}" -f $($PSStyle.Foreground.BrightGreen),$link,$($PSStyle.Reset)

#scripting
psedit .\MyFileSystem.format.ps1xml
Update-FormatData .\MyFileSystem.format.ps1xml

#directory links will open the folder in Windows Explorer
#some files will open in their associated application
dir c:\temp | Format-Table -view link

#PSBluesky formatting
# https://github.com/jdhitsolutions/PSBlueSky
https://github.com/jdhitsolutions/PSBluesky/blob/main/formats/PSBlueSkyTimelinePost.format.ps1xml#L29

# Get-BskyTimeline -Limit 3

#endregion

#region PowerShell.Exiting

#clean up your PowerShell session
#Must use EXIT

[void](Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $Now = Get-Date
    $ps = Get-Process -Id $pid
    [PSCustomObject]@{
        Id           = $ps.Id
        Name         = $ps.Name
        User         = (whoami).ToUpper()
        Computername = [System.Environment]::MachineName
        StartTime    = $ps.StartTime
        EndTime      = $Now
        Runtime      = New-TimeSpan -Start $ps.StartTime -End $Now
    } | Export-Csv -Path c:\logs\ps-exit.csv -Append -NoTypeInformation

    if ($PSClockSettings.Running) {
        $flag = "$ENV:temp\psclock-flag.txt"
        if (Test-Path $flag) {
            Remove-Item $flag -Force
        }
        Stop-PSClock
    }
})

Import-Csv C:\logs\ps-exit.csv | Select-Object -last 5 | Format-Table

#endregion

#region Module Closing
#put this in your root module to cleanup
# code C:\scripts\psclock\psclock.psm1
start 'https://github.com/jdhitsolutions/PSClock/blob/main/PSClock.psm1#L61'

#endregion

#region New-TemporaryFile

#avoid using .NET
#the cmdlet supports -WhatIf
Help new-temporaryFile

$t = New-TemporaryFile
Get-Date | Set-Content -path $t
Get-Item $t
Remove-Item $t

#endregion

#region Show-Module

#peek inside the module scope

#list private functions
&(Get-Module PSTuiTools) {Get-Command -module PSTuiTools | Where name -NotMatch '-'}

#list private variables
&(Get-Module PSTuiTools) {Get-Variable -scope script}

psedit .\Show-Module.ps1
. .\Show-Module.ps1
Import-Module PSBluesky
$m = Show-Module PSBluesky
$m.InternalFunctions
$m.Variables

Show-Module PSBluesky -VariableOnly

#endregion

#endregion scripting surprises
