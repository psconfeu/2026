function New-PersonalStorage {
    param (
        $Computer,
        [switch]$TimeTravel
    )

    if ($TimeTravel) {
        $Time = '00:00:05'
    } else {
        $Time = '01:00:00'
    }

    Show-Timer -Name "Creating Personal Storage on $Computer" -TotalTime $Time
}