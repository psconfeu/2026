[CmdletBinding()]
param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 8080
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-JsonResponse {
  param(
    [Parameter(Mandatory)]
    [System.Net.HttpListenerContext]$Context,

    [Parameter(Mandatory)]
    [int]$StatusCode,

    [Parameter(Mandatory)]
    [object]$Body
  )

  $json = $Body | ConvertTo-Json -Depth 8
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

  $Context.Response.StatusCode = $StatusCode
  $Context.Response.ContentType = 'application/json; charset=utf-8'
  $Context.Response.ContentLength64 = $bytes.Length
  $Context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Get-FortuneOracle {
  $rawFortune = (& fortune -l 2>&1 | Out-String).Trim()

  $rawFortune = $rawFortune -replace '(?m)^\s*--\s*[^\r\n]*(?:\r?\n\s*[\(\[][^\r\n]*[\)\]])*', '-- Grunkle Stan'

  $fortuneLines = $rawFortune -split "`r?`n"
  $headline = ($fortuneLines | Select-Object -First 1).Trim()

  return [pscustomobject]@{
    Headline  = $headline
    LineCount = $fortuneLines.Count
    FullText  = $rawFortune
  }
}

$listener = [System.Net.HttpListener]::new()
$prefix = "http://*:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Mystery Shack fortune oracle listening on $prefix" -ForegroundColor Green
Write-Host "Process id: $PID" -ForegroundColor DarkGray

if ($env:WAIT_FOR_DEBUGGER -eq '1') {
  Write-Host 'WAIT_FOR_DEBUGGER=1 detected. Pausing for debugger attach...' -ForegroundColor Yellow
  Wait-Debugger
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()

    try {
      switch ($context.Request.Url.AbsolutePath) {
        '/health' {
          Write-JsonResponse -Context $context -StatusCode 200 -Body @{
            status    = 'ok'
            service   = 'mystery-shack-fortune-oracle'
            processId = $PID
          }
        }

        '/fortune' {
          $oracle = Get-FortuneOracle

          Write-JsonResponse -Context $context -StatusCode 200 -Body @{
            location  = 'Mystery Shack'
            fortune   = $oracle.Headline
            lineCount = $oracle.LineCount
          }
        }

        default {
          Write-JsonResponse -Context $context -StatusCode 404 -Body @{
            error  = 'Unknown route.'
            routes = @('/health', '/fortune')
          }
        }
      }
    }
    catch {
      Write-JsonResponse -Context $context -StatusCode 500 -Body @{
        error = $_.Exception.Message
      }
    }
    finally {
      $context.Response.OutputStream.Close()
    }
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
