#!/usr/bin/env pwsh
# Demo definitions for basic process invocation patterns

Info {
    Title "Process Invocation"

    Introduction "Learn how PowerShell finds and executes native applications, including PATH lookup, relative/absolute paths, and the call operator."

    KeyConcepts @(
        "PATH resolution and Get-Command"
        "Call operator (&) vs dot sourcing (.)"
        "Invoke-Expression dangers"
    )

    Summary @"
PowerShell uses Get-Command to resolve executables and has different rules than bash/cmd for finding and invoking processes.

Key points:
  • PATH lookup happens automatically for known commands
  • Use & for variables/paths with spaces
  • Never use Invoke-Expression with untrusted input - it executes code, not just commands
"@

    CommonPitfalls @"
  • Using Invoke-Expression instead of the call operator
  • Forgetting ./ or .\ for scripts in the current directory
"@
}

Demo "Direct Invocation PATH lookup" {
    Description "Shows how PowerShell executes a binary found in PATH"

    Code { whoami }
}

Demo "Get-Command resolution" {
    Description "Shows how Get-Command resolves the command to be executed"

    Code {
        # Application
        Get-Command whoami

        # Function
        Get-Command prompt

        # Alias
        Get-Command mi
    }
}

Demo "Direct invocation using relative path" {
    Description "Shows how PowerShell executes a binary directly using a relative path"

    Setup {
        Push-Location "$PSScriptRoot/folder space"
    }

    if ($IsWindows) {
        Code { .\test.bat }
    }
    else {
        Code { ./test.sh }
    }
}

Demo "Direct invocation using absolute path" {
    Description "Shows how PowerShell executes a binary directly using an absolute path"

    if ($IsWindows) {
        Code { C:\Windows\System32\whoami.exe }
    }
    else {
        Code { /usr/bin/whoami }
    }
}

Demo "Call operator with variable" {
    Description "Shows how PowerShell executes a binary using the call operator with a variable"

    if ($IsWindows) {
        Code { & "$PSScriptRoot\folder space\test.bat" }
    }
    else {
         Code { & "$PSScriptRoot/folder space/test.sh" }
    }
}

Demo "Call operator and dot sourcing" {
    Description "Shows that for an application the call operator and dot sourcing have the same effect"

    Code {
        # Call operator
        & whoami

        # Dot sourcing
        . whoami
    }
}

Demo "Start-Job is in a new process" {
    Description "Shows that Start-Job creates a new process"

    Code {
        "Current PID $pid"

        Start-Job {
            "Job PID $pid"
        } | Receive-Job -Wait -AutoRemoveJob
    }
}

Demo "Invoke-Expression can work" {
    Description "Shows that Invoke-Expression can work but do not use"

    Setup {
        Push-Location "$PSScriptRoot/folder space"
    }

    if ($IsWindows) {
        Code { Invoke-Expression ".\test.bat" }
    }
    else {
        Code { Invoke-Expression "./test.sh" }
    }
}

Demo "Invoke-Expression breaking" {
    Description "Shows how Invoke-Expression can break due to whitespace and quoting issues"

    if ($IsWindows) {
        Code {
            Invoke-Expression ".\folder space\test.bat"
            # .\folder space\test.bat
        }
    }
    else {
        Code {
            Invoke-Expression "./folder space/test.sh"
            # ./folder space/test.sh
        }
    }
}

Demo "Invoke-Expression dangers" {
    Description "Shows the dangers of Invoke-Expression with untrusted input"

    Setup { Set-Alias echo-bin ($IsWindows ? "./stdio/echo.bat" : "/usr/bin/echo") }

    Code {
        $cmdInput = "Bobby Tables; whoami"

        "Direct Invocation Result:"
        echo-bin $cmdInput

        "`nIEX Result:"
        Invoke-Expression "echo-bin $cmdInput"

        "`nSafe IEX Result:"
        Invoke-Expression "echo-bin `"$cmdInput`""
    }
}

Demo "Invoke-Expression is insidious" {
    Description "Shows that Invoke-Expression can be dangerous even if you try and escape things"

    Setup { Set-Alias echo-bin ($IsWindows ? "./stdio/echo.bat" : "/usr/bin/echo") }

    Code {
        $cmdInput = 'Bobby Tables; $(whoami)'

        "Safe IEX Result is no longer safe:"
        Invoke-Expression "echo-bin `"$cmdInput`""
    }
}

if ($IsWindows) {
    . "$PSScriptRoot/01-invocation.windows.ps1"
}
