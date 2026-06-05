Info {
    Title "Exit Codes"

    Introduction "Learn how PowerShell captures exit codes in `$LASTEXITCODE and how to handle non-zero exits."

    KeyConcepts @(
        "Reading `$LASTEXITCODE after process execution"
        "Exit code error handling with `$PSNativeCommandUseErrorActionPreference"
    )

    Summary @"
PowerShell doesn't treat non-zero exit codes as errors by default - you must check `$LASTEXITCODE manually or enable automatic error handling.

Use `$PSNativeCommandUseErrorActionPreference = `$true (7.4+) to treat non-zero exits as errors based on `$ErrorActionPreference.
"@

    CommonPitfalls @"
  • Forgetting to check `$LASTEXITCODE
  • Assuming PowerShell will error on non-zero exit codes
"@
}

Demo "Return code retrieval" {
    Description 'Shows how PowerShell captures the exit code of a process in $LASTEXITCODE'
    Code {
        pwsh -Command 'exit 0'
        $LASTEXITCODE

        pwsh -Command 'exit 1'
        $LASTEXITCODE
    }
}

Demo "Return code error handling" {
    Description 'Shows how PowerShell treats non-zero exit codes'

    Code {
        $ErrorActionPreference = 'Stop'

        pwsh -Command 'exit 0'
        $LASTEXITCODE

        pwsh -Command 'exit 1'
        $LASTEXITCODE

        "This still runs"
    }
}

Demo "Error on non-zero exit code manually" {
    Description "Shows how to manually error on non-zero exit code"

    Code {
        pwsh -Command 'exit 0'
        if ($LASTEXITCODE) {
            throw "Process 1 failed with $LASTEXITCODE"
        }

        pwsh -Command 'exit 1'
        if ($LASTEXITCODE) {
            throw "Process 2 failed with $LASTEXITCODE"
        }
    }
}

Demo '$PSNativeCommandUseErrorActionPreference (7.4+)' {
    Description 'Shows how exit code failures can be treated as errors with $PSNativeCommandUseErrorActionPreference (available in PowerShell 7.4+)'

    Code {
        $ErrorActionPreference = 'Stop'
        $PSNativeCommandUseErrorActionPreference = $true

        pwsh -Command 'exit 1'
        "This won't run"
    }
}
