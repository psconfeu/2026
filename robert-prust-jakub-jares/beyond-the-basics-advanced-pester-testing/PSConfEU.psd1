@{
    RootModule        = 'PSConfEU.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'f8c1c20d-1d8e-4d52-9b5d-6a3c8d9a51b0'
    Author            = 'Robert Prust'
    CompanyName       = 'Wortell'
    Description       = 'PowerShell client for the PSConfEU Conference API. Workshop demo module for Pester.'
    PowerShellVersion = '7.4'
    FunctionsToExport = @(
        'Get-PSConfSession',
        'Get-PSConfSpeaker',
        'Get-PSConfSchedule',
        'Register-PSConfAttendee',
        'Submit-PSConfRating',
        'Get-PSConfRating',
        'Find-PSConfConflict',
        'Test-PSConfRating'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
