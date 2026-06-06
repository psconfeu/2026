function Get-SystemUser {
    param (
        [switch]$All,
        [switch]$TimeTravel
    )

    if ($TimeTravel) {
        $Time = '00:00:05'
    }
    else {
        $Time = '00:00:10'
    }

    Show-Timer -Name 'Getting System Users' -TotalTime $Time

    return [PSCustomObject]@{
        Username           = 'Jimbo'
        StartDate          = '2026-01-13'
        HasPersonalStorage = $false
        StoragePath        = $null
    }
}