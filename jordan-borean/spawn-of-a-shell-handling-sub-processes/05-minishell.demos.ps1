Info {
    Title "PowerShell Minishell"

    Introduction "The minishell pattern allows passing PowerShell objects to child pwsh processes via serialization."

    KeyConcepts @(
        "Using pwsh { scriptblock } syntax"
        "Object serialization through -EncodedCommand"
        "Minishell in other languages"
    )

    Summary @"
Minishells serialize objects via -EncodedCommand and -EncodedArguments, enabling rich data transfer to child processes.

Limitations:
  • Objects become read-only (deserialized)
  • Script methods don't transfer
  • Limited to PowerShell-to-PowerShell by default
"@

    CommonPitfalls @"
  • Expecting live objects with methods
  • Not understanding serialization depth limits
"@
}

Demo "Minishell definition" {
    Description "Shows how a PowerShell minishell is defined"

    Code {
        pwsh { 'some code here' }
    }
}

Demo "Minishell input/output" {
    Description "Shows how objects are serialized and deserialized (hydrated/dehydrated) through stdin and stdout in a minishell"

    Code {
        $obj = [PSCustomObject]@{
            Name = "Test Object"
            Value = 42
        }

        $out = $obj | pwsh {
            $obj = @($input)[0]
            $obj.Name = "Modified $($obj.Name)"
            $obj.Value += 10

            $obj
        }

        $out
    }
}

Demo "Minishell arguments" {
    Description "Shows how objects can be passed as arguments to a minishell"

    Code {
        $obj = [PSCustomObject]@{
            Name = "Test Object"
            Value = 42
        }

        $out = pwsh {
            param($obj)

            $obj.Name = "Modified $($obj.Name)"
            $obj.Value += 10

            $obj
        } -args $obj

        $out
    }
}

Demo "Minishell streams" {
    Description "Shows how PowerShell streams like verbose can be captured in a minishell"

    Code {
        pwsh {
            $VerbosePreference = 'Continue'

            Write-Verbose "This is a verbose message"
            "This is output"
        }
    }
}

Demo "Object serialization" {
    Description "Shows how objects are serialized and become read-only when passed to a minishell"

    Code {
        $obj = [PSCustomObject]@{Value = 1}
        $obj | Add-Member -MemberType ScriptMethod -Name Increment -Value { $this.Value++ }

        # Works normally
        $obj.Increment()
        $obj

        # Increment not accessible in minishell
        pwsh {
            param ($obj)
            $obj.Increment()
        } -args $obj
    }
}

Demo "Minishell implementation" {
    Description "Shows how the minishell works"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        $obj = [PSCustomObject]@{
            Name = "Test Object"
            Value = 42
        }

        print_argv { 'scriptblock' } -args $obj
    }
}

Demo "Minishell decoded arguments" {
    Description "Shows the raw strings for the minishell encoded arguments"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        $obj = [PSCustomObject]@{
            Name = "Test Object"
            Value = 42
        }
        $raw = print_argv { 'scriptblock' } -args $obj
        $encCommand = $null
        $encArgs = $null
        for ($i = 0; $i -lt $raw.Length; $i++) {
            if ($raw[$i] -like '* -encodedcommand' -and $raw.Length -gt ($i + 1)) {
                $encCommand = $raw[$i + 1] -split ' ' | Select-Object -Skip 1 | Select-Object -First 1
            }
            elseif ($raw[$i] -like '* -encodedarguments' -and $raw.Length -gt ($i + 1)) {
                $encArgs = $raw[$i + 1] -split ' ' | Select-Object -Skip 1 | Select-Object -First 1
            }

            if ($encCommand -and $encArgs) {
                break
            }
        }

        "Encoded Command"
        [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encCommand))

        "`nEncoded Arguments"
        [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encArgs))
    }
}

Demo "Minishell output" {
    Description "Shows how output from the minishell is captured"

    Code {
        $cmd = {
            $VerbosePreference = 'Continue'
            Write-Verbose "This is a verbose message"

            [PSCustomObject]@{ Name = "Test Object"; Value = 42 }
        }
        $encCmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))

        $procParams = @{
            FilePath = 'pwsh'
            ArgumentList = "-NonInteractive -EncodedCommand $encCmd -InputFormat xml -OutputFormat xml"
            Wait = $true
            RedirectStandardOutput = 'stdout.out'
            RedirectStandardError = 'stderr.out'
        }
        Start-Process @procParams

        Get-Content stdout.out
        Get-Content stderr.out
    }

    Teardown {
        Remove-Item stdout.out -ErrorAction Ignore
        Remove-Item stderr.out -ErrorAction Ignore
    }
}

Demo "Minishell in Python" {
    Description "Shows how other languages can also implement the minishell protocol, like Python"

    if ($IsWindows) {
        Code {
            Get-Content ./minishell/py-minishell.py

            ""
            uv run --quiet --script ./minishell/py-minishell.py
        }
    }
    else {
        Code {
            Get-Content ./minishell/py-minishell.py

            ""
            ./minishell/py-minishell.py
        }
    }
}
