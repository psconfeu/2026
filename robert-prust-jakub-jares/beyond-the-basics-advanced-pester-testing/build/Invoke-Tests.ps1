<#
.SYNOPSIS
    Single Pester entry point used by dev, container, and CI.
.PARAMETER Tag
    One or more tags to include (default: Unit).
.PARAMETER ExcludeTag
    Tags to exclude (default: Slow, Demo, Flaky).
.PARAMETER OutputFile
    NUnit XML output path (default: TestResults/<first-tag>.xml).
.PARAMETER Path
    Test path(s) to scan (default: ./Tests).
#>
[CmdletBinding()]
param(
    [string[]] $Tag        = @('Unit'),
    [string[]] $ExcludeTag = @('Slow','Demo','Flaky'),
    [string]   $OutputFile,
    [string[]] $Path       = @('./Tests')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable Pester | Where-Object Version -ge '5.5.0')) {
    throw 'Pester 5.5.0+ is required. Install with: Install-Module Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck'
}
Import-Module Pester -MinimumVersion 5.5.0 -Force

if (-not $OutputFile) {
    $null = New-Item -ItemType Directory -Path './TestResults' -Force
    $OutputFile = "./TestResults/$($Tag[0].ToLowerInvariant()).xml"
}

$config = New-PesterConfiguration
$config.Run.Path           = $Path
$config.Run.PassThru       = $true
$config.Filter.Tag         = $Tag
$config.Filter.ExcludeTag  = $ExcludeTag
$config.TestResult.Enabled      = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath   = $OutputFile
$config.Output.Verbosity   = 'Detailed'
$config.CodeCoverage.Enabled = $false

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) { exit 1 } else { exit 0 }
