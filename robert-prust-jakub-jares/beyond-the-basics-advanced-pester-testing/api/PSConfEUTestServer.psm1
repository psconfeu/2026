$script:ServerPid = $null
$script:ServerPort = $null

function Start-PSConfEUServer {
    <#
    .SYNOPSIS
        Starts the mock API in a background process and waits until it's ready.
    #>
    param(
        [int] $Port = 5000
    )

    $serverScript = Join-Path $PSScriptRoot 'Start-Server.ps1'
    $startArgs = @{
        FilePath     = 'pwsh'
        PassThru     = $true
        ArgumentList = "-NoProfile -Command `"& '$serverScript' -Port $Port`""
    }
    # -WindowStyle is Windows-only; it throws NotSupportedException on Linux/macOS
    # (e.g. the alpine test container). Hide the window only where it's supported.
    if ($IsWindows) { $startArgs.WindowStyle = 'Hidden' }
    $process = Start-Process @startArgs

    $script:ServerPid = $process.Id
    $script:ServerPort = $Port

    $deadline = (Get-Date).AddSeconds(30)
    $lastError = $null
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) {
            throw "API server process exited with code $($process.ExitCode) before becoming ready."
        }
        try {
            if ((Invoke-RestMethod "http://localhost:$Port/health" -TimeoutSec 1).status -eq 'ok') {
                return
            }
        }
        catch {
            $lastError = $_
            Start-Sleep -Milliseconds 200
        }
    }

    throw "API server did not start on port $Port within 30 seconds. Last error: $lastError"
}

function Stop-PSConfEUServer {
    <#
    .SYNOPSIS
        Stops the mock API and resets persisted data (ratings, attendees).
    #>

    if ($script:ServerPid) {
        Stop-Process -Id $script:ServerPid -Force -ErrorAction SilentlyContinue
        $script:ServerPid = $null
        $script:ServerPort = $null
    }

    $jsonDir = Join-Path $PSScriptRoot 'json'
    '[]' | Set-Content (Join-Path $jsonDir 'ratings.json') -Encoding UTF8
    '[]' | Set-Content (Join-Path $jsonDir 'attendees.json') -Encoding UTF8
}
