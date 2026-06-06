function Get-PersonalStorage {
    param (
        $Computer,
        [switch]$TimeTravel
    )

    if ($TimeTravel) {
        $Time = '00:00:05'
    }
    else {
        $Time = '06:00:00'
    }
    
    Show-Timer -Name "Gathering Personal Storage Info from $Computer" -TotalTime $Time

    return @(
        [PSCustomObject]@{
            User        = 'Jimbo'
            Path        = '\\bigcomputer\space\jimbo'
            LastBackup  = 'Never'
            PercentUsed = 'Not applicable'
        },
        [PSCustomObject]@{
            User        = 'Limbo'
            Path        = '\\bigcomputer\space\limbo'
            LastBackup  = '2026-01-24'
            PercentUsed = '92.6%'
        },
        [PSCustomObject]@{
            User        = 'Timbo'
            Path        = '\\bigcomputer\space\timbo'
            LastBackup  = '2025-03-07'
            PercentUsed = '152.4%'
        }
    )
}