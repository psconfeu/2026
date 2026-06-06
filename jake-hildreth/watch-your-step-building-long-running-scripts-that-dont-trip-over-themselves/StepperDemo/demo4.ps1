<#
.SYNOPSIS
    demo4

.DESCRIPTION
    Unmanaged code

.NOTES
    Managed by Stepper. Use New-Step blocks to define resumable steps.
#>
[CmdletBinding()]
param()
#region Stepper ignore
if (-not (Get-Module -Name Stepper) -and -not (Get-Module -ListAvailable -Name Stepper)) { Install-Module Stepper -Force }
$StepperConversionComplete = $true
#endregion Stepper ignore

New-Step -Name 'Get New Users' {
    $Stepper.NewUsers = Get-SystemUser -All -TimeTravel |
        Where-Object HasPersonalStorage -EQ $false # Typical runtime: 10 seconds
}
# Create personal storage for all new users on the big server.
# Typical runtime: 1 hour
New-Step 'Create Storage for New Users' {
    $Stepper.NewUsers | New-PersonalStorage -Computer BigServer -TimeTravel
}

# Get data about personal storage usage. 
# Typical runtime: 6 hours
New-Step -NoLog {
    $Stepper.PersonalStorageUsage = Get-PersonalStorage -Computer BigServer -TimeTravel |
    Select-Object User, Path, LastBackup, PercentUsed
}

# Export report about personal storage usage:
# Typical runtime: 10 minutes
New-Step -Retry -RetryInterval 1 -MaxRetries 5 {
    if ($null -eq $Stepper.RetryAttempt) {
        $Stepper.RetryAttempt = 0
    }
    $Stepper.RetryAttempt++
    
    if ($Stepper.RetryAttempt -lt 3) {
        throw "Transient error (attempt $($Stepper.RetryAttempt)). Will retry..."
    }
    Write-Host "Success on attempt $($Stepper.RetryAttempt)!"
    $Stepper.PersonalStorageUsage | Export-Excel .\PersonalStorageReport.xlsx
}

Stop-Stepper
