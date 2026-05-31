function Write-CrashDump {
  param(
    [Parameter(Mandatory)]
    [System.Management.Automation.ErrorRecord]$ErrorRecord,

    [Parameter()]
    [string]$BaseNamePrefix = 'pwsh_crashdump',

    [Parameter()]
    [string]$CrashDumpBasePath = $env:TEMP
  )

  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
  $baseName = "${BaseNamePrefix}_$timestamp"

  if (-not $CrashDumpBasePath) {
    $CrashDumpBasePath = [System.IO.Path]::GetTempPath()
  }

  $dumpRoot = Join-Path $CrashDumpBasePath $baseName
  New-Item -ItemType Directory -Path $dumpRoot -Force | Out-Null

  $ErrorRecord | Format-List * -Force | Out-File (Join-Path $dumpRoot 'Exception.txt') -Width 5000
  $ErrorRecord | Export-Clixml (Join-Path $dumpRoot 'ErrorRecord.xml')

  Get-PSCallStack | Format-Table -AutoSize | Out-File (Join-Path $dumpRoot 'CallStack.txt') -Width 5000

  $allVariables = Get-Variable | Where-Object {
    $_.Name -notmatch '^global:|^script:|^private:'
  }

  $allVariables | Sort-Object Name | Format-Table Name, @{
    Name       = 'Type'
    Expression = { $_.Value?.GetType()?.FullName }
  }, Value -AutoSize | Out-File (Join-Path $dumpRoot 'Variables.txt') -Width 5000

  $allVariables | Export-Clixml (Join-Path $dumpRoot 'Variables.xml')

  @{
    Time                   = Get-Date
    PowerShellVersion      = $PSVersionTable.PSVersion.ToString()
    PSEdition              = $PSVersionTable.PSEdition
    OS                     = [System.Environment]::OSVersion.ToString()
    MachineName            = $env:COMPUTERNAME
    User                   = $env:USERNAME
    ProcessId              = $PID
    CurrentDirectory       = (Get-Location).Path
    CommandLine            = [Environment]::CommandLine
    Culture                = [System.Globalization.CultureInfo]::CurrentCulture.Name
    UICulture              = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    Is64BitProcess         = [Environment]::Is64BitProcess
    Is64BitOperatingSystem = [Environment]::Is64BitOperatingSystem
  } | ConvertTo-Json -Depth 5 | Out-File (Join-Path $dumpRoot 'Environment.json')

  Get-Module | Sort-Object Name | Format-Table Name, Version, Path -AutoSize | Out-File (Join-Path $dumpRoot 'Modules.txt') -Width 5000

  [AppDomain]::CurrentDomain.GetAssemblies() | Sort-Object FullName | Select-Object FullName, Location |
  Format-Table -AutoSize | Out-File (Join-Path $dumpRoot 'Assemblies.txt') -Width 5000

  Get-Process -Id $PID | Format-List * | Out-File (Join-Path $dumpRoot 'Process.txt') -Width 5000

  $Error | Select-Object -First 50 | Format-List * -Force |	Out-File (Join-Path $dumpRoot 'RecentErrors.txt') -Width 5000

  return $dumpRoot
}
