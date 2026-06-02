[CmdletBinding()]
param(
  [string]$Town = 'Gravity Falls'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$trapHandlerScript = Join-Path $PSScriptRoot 'crashhandler_trap.ps1'
. $trapHandlerScript

trap {
  $dumpRoot = Write-CrashDump -ErrorRecord $_ -BaseNamePrefix 'AnomalyScan'
  Write-Host "Crash dump written to: $dumpRoot" -ForegroundColor Red
  break
}

function Write-Section {
  param([string]$Title)

  Write-Host ''
  Write-Host '============================================================='
  Write-Host $Title -ForegroundColor Cyan
  Write-Host '============================================================='
}

function Get-AnomalyScore {
  param(
    [Parameter(Mandatory)]
    [pscustomobject]$Location
  )

  <#
  if ($Location.ExpectedSignals -eq 0) {
    return [double]::PositiveInfinity
  }
  #>

  $confidence = $Location.ObservedSignals / $Location.ExpectedSignals
  return [math]::Round($confidence * 100, 2)
}

function Get-AnomalyReport {
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [pscustomobject[]]$Locations
  )

  $report = foreach ($location in $Locations) {
    $score = Get-AnomalyScore -Location $location

    [pscustomobject]@{
      Location        = $location.Name
      ObservedSignals = $location.ObservedSignals
      ExpectedSignals = $location.ExpectedSignals
      AnomalyScore    = $score
      Notes           = $location.Notes
    }
  }

  $sortedReport = $report | Sort-Object -Property @{ Expression = { $_.AnomalyScore }; Descending = $true }
  return $sortedReport
}

$locations = @(
  [pscustomobject]@{
    Name            = 'The Mystery Shack'
    ObservedSignals = 12
    ExpectedSignals = 4
    Notes           = 'Tourist trap energy is unusually high.'
  }
  [pscustomobject]@{
    Name            = 'Journal #3 vault'
    ObservedSignals = 7
    ExpectedSignals = 3
    Notes           = 'Artifact field spikes whenever the journal is nearby.'
  }
  [pscustomobject]@{
    Name            = 'Northwest Manor'
    ObservedSignals = 4
    ExpectedSignals = 2
    Notes           = 'Poltergeist readings stay stable.'
  }
  [pscustomobject]@{
    Name            = 'Old Shack Basement'
    ObservedSignals = 0
    ExpectedSignals = 0
    Notes           = 'No anomaly signature detected, which is itself suspicious.'
  }
)

Write-Host "Town: $Town"
Write-Section 'Scanning locations'
$report = $locations | Get-AnomalyReport

Write-Section 'Results'
$report |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Scan complete.' -ForegroundColor Green
