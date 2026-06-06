using namespace System.IO
using namespace System.IO.Pipes

Info {
    Title "Passing Secrets to Processes"

    Introduction "Command-line arguments expose secrets in process lists. We'll explore safer methods: environment variables, stdin, and platform-specific SecureString behavior."

    KeyConcepts @(
        "Why command-line args are unsafe"
        "Environment variables vs stdin"
        "SecureString differences: Windows vs Linux"
    )

    $codeExample = @'
# Windows: DPAPI encryption (secure)
# Linux: XOR obfuscation (NOT secure)
$secure = ConvertTo-SecureString 'secret' -AsPlainText
'@ | Format-PowerShell

    Summary @"
Never use command-line arguments - they're visible in process lists.

Preferred approaches:
  • stdin - safest for one-way transfers to external processes
  • Start-Job -ArgumentList - keeps secrets in-memory for PowerShell
  • Environment variables - OK but clear immediately after use

Platform differences matter:

$codeExample

On Linux, SecureString provides no real protection - prefer stdin or env vars.
"@

    CommonPitfalls @"
  • Trusting SecureString on Linux
  • Not clearing environment variables
  • Logging commands with secrets
"@
}

Demo "Command line arg secrets (bad)" {
    Description "Shows why command line arguments are not good for secrets (they're visible in process lists)"

    Code {
        $secret = "Super secret"
        pwsh -CommandWithArgs '$args[0]' $secret
    }
}

Demo "Environment variable secrets (ok)" {
    Description "Shows how secrets can be shared through environment variables"

    Code {
        $env:SECRET = "This is my secret value, no snooping"
        try {
            pwsh -Command '$env:SECRET'
        }
        finally {
            $env:SECRET = $null
        }
    }
}

Demo "Stdin secrets (ok)" {
    Description "Shows how secrets can be shared through stdin"

    Code {
        $secret = "Is it secret? Is it safe?"

        $secret | pwsh -Command '$input'
    }
}

Demo "SecureString through minishell" {
    Description "Shows how SecureString objects can be provided to a minishell (only secure on Windows)"

    Code {
        $secret = ConvertTo-SecureString 'AustraliaRulz' -AsPlainText -Force

        pwsh {
            param($Secret)

            [Net.NetworkCredential]::new("", $Secret).Password
        } -args $secret
    }
}

if ($IsWindows) {
    Demo "SecureString serialization (Windows)" {
        Description "Shows how SecureString objects are serialized in minishells and remain encrypted on Windows"

        Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

        Code {
            $secret = ConvertTo-SecureString 'WindowsHappy' -AsPlainText -Force

            $raw = print_argv {} -args $secret
            $encArgs = $null
            for ($i = 0; $i -lt $raw.Length; $i++) {
                if ($raw[$i] -like '* -encodedarguments' -and $raw.Length -gt ($i + 1)) {
                    $encArgs = $raw[$i + 1] -split ' ' | Select-Object -Skip 1 | Select-Object -First 1
                    break
                }
            }
            if (-not $encArgs) {
                throw "Encoded arguments not found in argv output"
            }

            $clixml = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encArgs))
            $clixml

            Format-Hex -InputObject ([Convert]::FromHexString(([xml]$clixml).Objs.Obj.LST.SS))
        }
    }

    if (Get-Command -Name wsl.exe -ErrorAction Ignore) {
        $null = wsl.exe -- /bin/bash -lc 'command -v pwsh'
        if ($LASTEXITCODE -eq 0) {
            Demo "SecureString serialization (Linux)" {
                Description "Shows how SecureString objects are serialized in minishells and not actually secret on Linux"

                Code {
                    # $secret = ConvertTo-SecureString 'LinuxSad' -AsPlainText -Force

                    $argvPath = wsl.exe -- /bin/bash -lc "wslpath '$PSScriptRoot\argv\linux_argv'"
                    $raw = wsl.exe -- /bin/bash -lc "pwsh -Command '& ""$argvPath"" {} -args (ConvertTo-SecureString -AsPlainText LinuxSad)'"
                    $encArgs = $null
                    for ($i = 0; $i -lt $raw.Length; $i++) {
                        if ($raw[$i] -like '* -encodedarguments' -and $raw.Length -gt ($i + 1)) {
                            $encArgs = $raw[$i + 1] -split ' ' | Select-Object -Skip 1 | Select-Object -First 1
                            break
                        }
                    }
                    if (-not $encArgs) {
                        throw "Encoded arguments not found in argv output"
                    }

                    $clixml = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encArgs))
                    $clixml

                    [Text.Encoding]::Unicode.GetString([Convert]::FromHexString(([xml]$clixml).Objs.Obj.LST.SS))
                }
            }
        }
    }
}
else {
    Demo "SecureString serialization (Linux)" {
        Description "Shows how SecureString objects are serialized in minishells and not actually secret on Linux"

        Setup { Set-Alias print_argv "./argv/linux_argv" }

        Code {
            $secret = ConvertTo-SecureString 'LinuxSad' -AsPlainText -Force

            $raw = print_argv {} -args $secret
            $encArgs = $null
            for ($i = 0; $i -lt $raw.Length; $i++) {
                if ($raw[$i] -like '* -encodedarguments' -and $raw.Length -gt ($i + 1)) {
                    $encArgs = $raw[$i + 1] -split ' ' | Select-Object -Skip 1 | Select-Object -First 1
                    break
                }
            }
            if (-not $encArgs) {
                throw "Encoded arguments not found in argv output"
            }

            $clixml = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encArgs))
            $clixml

            [Text.Encoding]::Unicode.GetString([Convert]::FromHexString(([xml]$clixml).Objs.Obj.LST.SS))
        }
    }
}

Demo "Start-Job -ArgumentList" {
    Description "Shows how Start-Job -ArgumentList provides a nice way to share secrets when spawning a new PowerShell process"

    Code {
        $secret = ConvertTo-SecureString 'StartJobSecret' -AsPlainText -Force

        Start-Job -ScriptBlock {
            param($Secret)

            "Cmd Args"
            [Environment]::GetCommandLineArgs()

            "`nSecret Value:"
            [Net.NetworkCredential]::new("", $Secret).Password
        } -ArgumentList $secret | Receive-Job -Wait -AutoRemoveJob
    }
}

Demo "Anonymous pipe secrets (bonus)" {
    Description "Shows how secrets can be shared through an anonymous pipe"

    Code {
        $server = [AnonymousPipeServerStream]::new(
            [PipeDirection]::Out,
            [HandleInheritability]::Inheritable)
        $writer = [StreamWriter]::new($server)
        $writer.WriteLine("Secret through pipe")
        $writer.Flush()

        # This can be any executable, just needs to accept the
        # pipe handle as an argument and read from it.
        pwsh {
            param($HandleId)

            $client = [IO.Pipes.AnonymousPipeClientStream]::new(
                [IO.Pipes.PipeDirection]::In, $HandleId)
            $reader = [IO.StreamReader]::new($client)
            $reader.ReadLine()
        } -args $server.GetClientHandleAsString()

        $server.Dispose()
    }
}
