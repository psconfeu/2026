[CmdletBinding()]
param(
  [ValidateRange(1024, 65535)]
  [int]$HostPort = 8182,

  [string]$ImageName = 'mystery-shack-fortune',

  [string]$ContainerName = 'mystery-shack-fortune',

  [switch]$Detached,

  [switch]$WaitForDebugger
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$containerPath = Join-Path $PSScriptRoot 'fortune-container'

Write-Host "Building Docker image: $ImageName" -ForegroundColor Cyan
& docker build -t $ImageName $containerPath
if ($LASTEXITCODE -ne 0) {
  throw 'Docker build failed.'
}

$runArgs = @(
  'run',
  '--rm',
  '--name', $ContainerName,
  '-p', "${HostPort}:8080",
  '--cap-add=SYS_PTRACE',
  '--security-opt', 'seccomp=unconfined'
)

if ($WaitForDebugger) {
  $runArgs += @('-e', 'WAIT_FOR_DEBUGGER=1')
}

if ($Detached) {
  $runArgs += '-d'
}
else {
  $runArgs += '-it'
}

$runArgs += $ImageName

Write-Host ''
Write-Host 'Container runtime hints:' -ForegroundColor Yellow
Write-Host '  - app endpoints:'
Write-Host "         http://localhost:$HostPort/health"
Write-Host "         http://localhost:$HostPort/fortune"
Write-Host "  - attach target: $ContainerName"
Write-Host '  - if you want the process to pause for debugger attach, pass -WaitForDebugger'
Write-Host ''

& docker @runArgs
