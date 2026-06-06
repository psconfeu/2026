function Show-Timer {
    param(
        [string]$Name = "Timer",
        [string]$TotalTime = "00:05:00"
    )

    $total = [TimeSpan]::Parse($TotalTime)
    $start = Get-Date
    $lastRemainingUpdate = -5
    $remaining = $total.TotalSeconds

    function Format-TimeWords([TimeSpan]$ts) {
        $parts = @()
        if ($ts.Hours -gt 0) { $parts += "$($ts.Hours) hour$(if ($ts.Hours -ne 1) {'s'})" }
        if ($ts.Minutes -gt 0) { $parts += "$($ts.Minutes) minute$(if ($ts.Minutes -ne 1) {'s'})" }
        $parts += "$($ts.Seconds) second$(if ($ts.Seconds -ne 1) {'s'})"
        $parts -join ' '
    }

    while ($true) {
        $elapsed = (Get-Date) - $start
        if ($elapsed -ge $total) { break }
    
        if (([int]$elapsed.TotalSeconds - $lastRemainingUpdate) -ge 5) {
            $remaining = ($total - $elapsed).TotalSeconds * (Get-Random -Minimum 0.8 -Maximum 1.2)
            $lastRemainingUpdate = [int]$elapsed.TotalSeconds
        }
        $pct = [math]::Min(100, ($elapsed.TotalSeconds / $total.TotalSeconds) * 100)
    
        $elapsedWords = Format-TimeWords $elapsed
        $remainingWords = Format-TimeWords ([TimeSpan]::FromSeconds($remaining))
    
        Write-Progress -Activity $Name `
            -Status "Elapsed: $elapsedWords | Remaining: $remainingWords (est)" `
            -PercentComplete $pct
    
        Start-Sleep -Seconds 1
    }

    Write-Progress -Activity $Name -Completed
    Write-Host "$Name - Complete!" -ForegroundColor Green
}