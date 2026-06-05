Info {
    Title "Standard Input/Output"

    Introduction "Understand how PowerShell handles stdin, stdout, and stderr with encoding control and stream separation."

    KeyConcepts @(
        "Piping data to stdin with encoding"
        "Reading stdout and controlling output encoding"
        "Separating stdout and stderr streams"
    )

    Summary @"
PowerShell converts objects to strings for stdin and reads stdout as strings (or raw bytes in 7.4+).

Key points:
  • `$OutputEncoding controls stdin encoding
  • [Console]::OutputEncoding (or `$PSApplicationOutputEncoding in 7.7+) controls stdout reading
  • Native-to-native pipelines preserve raw bytes
  • Use 2>variable:name (7.6+) to separate stderr cleanly
"@

    CommonPitfalls @"
  • Not setting `$OutputEncoding for non-ASCII stdin
  • Expecting stderr to be captured like PowerShell error streams
"@
}

Demo "Piping to stdin" {
    Description "Shows how strings are piped to stdin of a native process"

    Code {
        "line 1", "line 2" | pwsh -File ./stdio/echo-stdin.ps1
    }
}

Demo "Piping objects to stdin" {
    Description "Shows how complex objects are converted to strings when piped to stdin"

    Code {
        @{ Key = 'Value' } | pwsh -File ./stdio/echo-stdin.ps1
    }
}

Demo 'Stdin encoding rules' {
    Description 'Shows how $OutputEncoding controls the encoding of stdin'

    Code {
        $OutputEncoding = [Text.Encoding]::GetEncoding(437)

        'Café ☕' | pwsh -File ./stdio/echo-stdin.ps1 -Encoding raw

        $OutputEncoding = [Text.UTF8Encoding]::new()

        'Café ☕' | pwsh -File ./stdio/echo-stdin.ps1 -Encoding raw

        $OutputEncoding = [Text.Encoding]::UTF8

        'Café ☕' | pwsh -File ./stdio/echo-stdin.ps1 -Encoding raw
    }
}

Demo "Piping bytes to stdin (7.4+)" {
    Description 'Shows how to pipe raw bytes to stdin (available in PowerShell 7.4+)'

    Code {
        $OutputEncoding = [Text.Encoding]::GetEncoding(437)
        $str = 'Café ☕'
        $rawBytes = [Text.UTF8Encoding]::new().GetBytes($str)

        $rawBytes | pwsh -File ./stdio/echo-stdin.ps1 -Encoding utf-8
        $rawBytes | pwsh -File ./stdio/echo-stdin.ps1 -Encoding raw
    }
}

Demo 'Reading stdout' {
    Description 'Shows how to read stdout from a process'

    Code {
        $out = pwsh -Command '"some string value"; "string with newline `n value"; "another string value"'
        $out.GetType().FullName
        $out.Length
        ConvertTo-Json -InputObject $out
    }

}

Demo 'Stdout encoding' {
    Description 'Shows how stdout encoding works and how to control it'

    Setup {
        $env:_OLD_CODEPAGE = [Console]::OutputEncoding.CodePage
    }

    Code {
        $val = 'Café ☕'
        $utf8 = [Text.UTF8Encoding]::new()
        $b64 = [Convert]::ToBase64String($utf8.GetBytes($val))

        [Console]::OutputEncoding = $utf8
        pwsh -File ./stdio/echo-stdout.ps1 -Value $b64 -ConsoleEncoding utf-8

        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(437)
        pwsh -File ./stdio/echo-stdout.ps1 -Value $b64 -ConsoleEncoding utf-8
        pwsh -File ./stdio/echo-stdout.ps1 -Value $b64 -ConsoleEncoding 437
    }

    Teardown {
        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding([int]$env:_OLD_CODEPAGE)
        $env:_OLD_CODEPAGE = $null
    }
}

Demo '$PSApplicationOutputEncoding (7.7+)' {
    Description 'Shows how to control output encoding using $PSApplicationOutputEncoding (available in PowerShell 7.7+)'

    Setup {
        $env:_OLD_CODEPAGE = [Console]::OutputEncoding.CodePage
    }

    Code {
        if (-not (Get-Variable -Name PSApplicationOutputEncoding -ErrorAction Ignore)) {
            Write-Warning "This demo requires PowerShell 7.7 or later"
            return
        }

        $val = 'Café ☕'
        $utf8 = [Text.UTF8Encoding]::new()
        $b64 = [Convert]::ToBase64String($utf8.GetBytes($val))

        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(437)

        pwsh -File ./stdio/echo-stdout.ps1 -Value $b64 -ConsoleEncoding utf-8

        $PSApplicationOutputEncoding = $utf8
        pwsh -File ./stdio/echo-stdout.ps1 -Value $b64 -ConsoleEncoding utf-8
    }

    Teardown {
        [Console]::OutputEncoding = [Text.Encoding]::GetEncoding([int]$env:_OLD_CODEPAGE)
        $env:_OLD_CODEPAGE = $null
    }
}

Demo 'Stdout vs stderr' {
    Description 'Shows how PowerShell captures the separate streams'

    Code {
        @(
            '{"Stream": "stdout", "Value": "some stdout value"}'
            '{"Stream": "stderr", "Value": "some stderr value"}'
        ) | pwsh -File ./stdio/echo-stdout-stderr.ps1
    }
}

Demo 'Stdout null with stderr' {
    Description 'Shows how PowerShell captures the separate streams even when stdout is null'

    Code {
        @(
            '{"Stream": "stdout", "Value": "some stdout value"}'
            '{"Stream": "stderr", "Value": "some stderr value"}'
        ) | pwsh -File ./stdio/echo-stdout-stderr.ps1 | Out-Null
    }
}

Demo 'Stderr null with stdout' {
    Description 'Shows how PowerShell captures the separate streams even when stderr is null'

    Code {
        @(
            '{"Stream": "stdout", "Value": "some stdout value"}'
            '{"Stream": "stderr", "Value": "some stderr value"}'
        ) | pwsh -File ./stdio/echo-stdout-stderr.ps1 2>$null
    }
}

Demo 'Separating streams' {
    Description 'Shows how to capture stdout and stderr into separate variables'

    Code {
        $data = @(
            '{"Stream": "stdout", "Value": "some stdout value"}'
            '{"Stream": "stderr", "Value": "some stderr value"}'
        )

        $stdout = $null
        $stderr = . {
            $data | pwsh -File ./stdio/echo-stdout-stderr.ps1 | Set-Variable -Name stdout
        } 2>&1 | ForEach-Object ToString

        [PSCustomObject]@{
            Stdout = $stdout
            Stderr = $stderr
        }
    }
}

Demo 'Separating streams with variable redirection (7.6+)' {
    Description 'Shows how to capture stdout and stderr into separate variables using variable redirection (available in PowerShell 7.6+)'

    Code {
        $data = @(
            '{"Stream": "stdout", "Value": "some stdout value"}'
            '{"Stream": "stderr", "Value": "some stderr value"}'
        )

        $stderr = $null
        $stdout = $data | pwsh -File ./stdio/echo-stdout-stderr.ps1 2>variable:stderr

        [PSCustomObject]@{
            Stdout = $stdout
            Stderr = $stderr
        }
    }
}

Demo "Native byte pipelines" {
    Description "Pipelining between native applications uses raw bytes and is not affected by PowerShell's encoding settings"

    Code {
        $data = [byte[]](0xDE, 0xAD, 0xBE, 0xEF)

        # Normally non-string values can be scrambled when pwsh encodes to
        # a string
        $data | pwsh -File ./stdio/echo-stdin.ps1 -Encoding passthrough |
            Format-Hex

        # But when the pipeline is between native applications it is piped as
        # the raw bytes.
        $data | pwsh -File ./stdio/echo-stdin.ps1 -Encoding passthrough |
            pwsh -File ./stdio/echo-stdin.ps1 -Encoding raw
    }
}

Demo 'File redirection' {
    Description "File redirection also pipes the raw bytes"

    Code {
        $data = [byte[]](0xDE, 0xAD, 0xBE, 0xEF)

        $data | pwsh -File ./stdio/echo-stdin.ps1 -Encoding passthrough > file.bin
        Format-Hex -Path file.bin
    }

    Teardown {
        Remove-Item -Path file.bin -ErrorAction Ignore
    }
}

Demo "Capturing output" {
    Description "Using JSON is a nice way to capture structured output from a process"

    Code {
        $out = pwsh -Command '@{Key=@(1, 2, 3)} | ConvertTo-Json' | ConvertFrom-Json

        $out.Key
    }
}
