#requires -version 7.6
#requires -module PSReadline

Set-PSReadLineKeyHandler -Function capitalizeword -Chord 'alt+c'
Set-PSReadLineKeyHandler -Function upcaseword -Chord 'alt+u'
Set-PSReadLineKeyHandler -Function downcaseword -Chord 'alt+l'
Set-PSReadLineKeyHandler -key F12 -Function CaptureScreen

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

$sb = {
    Get-PSReadLineKeyHandler | where group -EQ custom |
    Select-Object Key,Function,Description |
    Out-GridView -Title "My custom key handlers"
}

Set-PSReadLineKeyHandler -key "Alt+k" -BriefDescription "ListMyHandlers" -Description "List my PSReadLine KeyHandlers" -ScriptBlock $sb
