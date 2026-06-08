<#
.SYNOPSIS
    This script is used to invoke Pester tests in the repository. It allows you to filter tests by tag and outputs the test results in NUnit XML format.
#>
param(
    [Parameter(HelpMessage = 'The tag to filter tests by')]
    [string]$Tag
)

$ResultPath = [IO.Path]::GetTempFileName()

$PesterConfig = New-PesterConfiguration -HashTable @{
    Filter = @{
        Tag = $Tag
    }
    Run = @{
        Path = Join-Path $Repository "Tests"
    }
    TestResult = @{
        Enabled = $true
        Path = $ResultPath
        Format = 'NUnitXml'
    }
}

if ($Tag) {
    $Tag = '*Tests.ps1'
}

Invoke-Pester -Configuration $PesterConfig

Get-Content -Path $ResultPath -Raw