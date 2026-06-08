function Sample {
    param(
        [ValidateSet('Monday','Tuesday','Wednesday')]
        $Day
    )
    Write-Host "Its $Day"
}

Sample 'Friday'


function Sample {
    param(
        [ValidateSet('Monday','Tuesday','Wednesday')]
        $Day = "Friday"
    )
    Write-Host "Its $Day"
}

Sample

enum acceptedInput {
    Monday
    Tuesday
    Wednesday
}

function Sample {
    param(
        [acceptedInput] $Day = "Friday"
    )
    Write-Host "Its $Day"
}

Sample