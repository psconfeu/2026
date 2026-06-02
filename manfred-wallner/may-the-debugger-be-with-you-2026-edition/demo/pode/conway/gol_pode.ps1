param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 8080,

  [ValidateRange(5, 300)]
  [int]$DefaultWidth = 10,

  [ValidateRange(5, 200)]
  [int]$DefaultHeight = 10,

  [ValidateRange(0.0, 1.0)]
  [double]$DefaultDensity = 0.28,

  [switch]$DefaultWrap,

  [int]$DefaultSeed = 42
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module Pode -ErrorAction Stop

function Test-BoardGameOver {
  param(
    [bool[, ]]$Board,
    [int]$Width,
    [int]$Height
  )
  for ($y = 0; $y -lt $Height; $y++) {
    for ($x = 0; $x -lt $Width; $x++) {
      if ($Board[$y, $x]) { return $false }
    }
  }
  return $true
}

function New-LifeBoard {
  param(
    [int]$Width,
    [int]$Height,
    [double]$Density,
    [int]$Seed
  )

  $board = [bool[, ]]::new($Height, $Width)
  $rng = [System.Random]::new($Seed)

  for ($y = 0; $y -lt $Height; $y++) {
    for ($x = 0; $x -lt $Width; $x++) {
      $board[$y, $x] = ($rng.NextDouble() -lt $Density)
    }
  }

  return , $board
}

function Get-LifeNeighborCount {
  param(
    [bool[, ]]$Board,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [bool]$Wrap
  )

  $count = 0

  for ($dy = -1; $dy -le 1; $dy++) {
    for ($dx = -1; $dx -le 1; $dx++) {
      if ($dx -eq 0 -and $dy -eq 0) {
        continue
      }

      $nx = $X + $dx
      $ny = $Y + $dy

      if ($Wrap) {
        $nx = ($nx + $Width) % $Width
        $ny = ($ny + $Height) % $Height
        if ($Board[$ny, $nx]) {
          $count++
        }
        continue
      }

      if ($nx -ge 0 -and $nx -lt $Width -and $ny -ge 0 -and $ny -lt $Height) {
        if ($Board[$ny, $nx]) {
          $count++
        }
      }
    }
  }

  return $count
}

function Step-LifeBoard {
  param(
    [bool[, ]]$Board,
    [int]$Width,
    [int]$Height,
    [bool]$Wrap
  )

  $next = [bool[, ]]::new($Height, $Width)

  for ($y = 0; $y -lt $Height; $y++) {
    for ($x = 0; $x -lt $Width; $x++) {
      $neighbors = Get-LifeNeighborCount -Board $Board -X $x -Y $y -Width $Width -Height $Height -Wrap $Wrap
      $alive = $Board[$y, $x]

      if ($alive) {
        $next[$y, $x] = ($neighbors -eq 2 -or $neighbors -eq 3)
      }
      else {
        $next[$y, $x] = ($neighbors -eq 3)
      }
    }
  }

  return , $next
}

function Get-BoardRows {
  param(
    [bool[, ]]$Board,
    [int]$Width,
    [int]$Height
  )

  $rows = [System.Collections.Generic.List[string]]::new($Height)

  for ($y = 0; $y -lt $Height; $y++) {
    $line = [System.Text.StringBuilder]::new($Width)
    for ($x = 0; $x -lt $Width; $x++) {
      if ($Board[$y, $x]) {
        [void]$line.Append('1')
      }
      else {
        [void]$line.Append('0')
      }
    }
    [void]$rows.Add($line.ToString())
  }

  return $rows.ToArray()
}

function New-LifeStatePayload {
  param(
    [hashtable]$State
  )

  $gameOver = Test-BoardGameOver -Board $State.Board -Width $State.Width -Height $State.Height
  return @{
    generation = $State.Generation
    width      = $State.Width
    height     = $State.Height
    wrap       = $State.Wrap
    seed       = $State.Seed
    rows       = @(Get-BoardRows -Board $State.Board -Width $State.Width -Height $State.Height)
    gameOver   = $gameOver
  }
}

$publicPath = Join-Path $PSScriptRoot 'public'
if (-not (Test-Path -LiteralPath $publicPath -PathType Container)) {
  throw "Missing public web assets folder: $publicPath"
}

$serverPort = $Port
$initialWidth = $DefaultWidth
$initialHeight = $DefaultHeight
$initialDensity = $DefaultDensity
$initialSeed = $DefaultSeed
$initialWrap = [bool]$DefaultWrap.IsPresent

Start-PodeServer -Threads 2 -ScriptBlock {
  Add-PodeEndpoint -Address '*' -Port $serverPort -Protocol Http

  Add-PodeBodyParser -ContentType 'application/json' -ScriptBlock {
    param($body)

    if ([string]::IsNullOrWhiteSpace($body)) {
      return @{}
    }

    return ($body | ConvertFrom-Json -AsHashtable -Depth 32)
  }

  $state = [hashtable]::Synchronized(@{
      Width      = $initialWidth
      Height     = $initialHeight
      Density    = $initialDensity
      Seed       = $initialSeed
      Wrap       = $initialWrap
      Generation = 0
      Board      = New-LifeBoard -Width $initialWidth -Height $initialHeight -Density $initialDensity -Seed $initialSeed
    })
  Set-PodeState -Name 'life' -Value $state

  Add-PodeStaticRoute -Path '/' -Source $publicPath -Defaults @('index.html')

  Add-PodeRoute -Method Get -Path '/api/state' -ScriptBlock {
    $state = Get-PodeState -Name 'life'
    Write-PodeJsonResponse -Value (New-LifeStatePayload -State $state)
  }

  Add-PodeRoute -Method Post -Path '/api/reset' -ScriptBlock {
    $state = Get-PodeState -Name 'life'
    $data = $WebEvent.Data

    $width = if ($null -ne $data.width) { [int]$data.width } else { $state.Width }
    $height = if ($null -ne $data.height) { [int]$data.height } else { $state.Height }
    $density = if ($null -ne $data.density) { [double]$data.density } else { $state.Density }
    $seed = if ($null -ne $data.seed) { [int]$data.seed } else { [Environment]::TickCount }
    $wrap = if ($null -ne $data.wrap) { [bool]$data.wrap } else { $state.Wrap }

    if ($width -lt 5 -or $width -gt 300) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{ error = 'width must be between 5 and 300' }
      return
    }
    if ($height -lt 5 -or $height -gt 200) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{ error = 'height must be between 5 and 200' }
      return
    }
    if ($density -lt 0.0 -or $density -gt 1.0) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{ error = 'density must be between 0 and 1' }
      return
    }

    $state.Width = $width
    $state.Height = $height
    $state.Density = $density
    $state.Seed = $seed
    $state.Wrap = $wrap
    $state.Generation = 0
    $state.Board = New-LifeBoard -Width $width -Height $height -Density $density -Seed $seed

    Write-PodeJsonResponse -Value (New-LifeStatePayload -State $state)
  }

  Add-PodeRoute -Method Post -Path '/api/step' -ScriptBlock {
    $state = Get-PodeState -Name 'life'
    $data = $WebEvent.Data
    $steps = if ($null -ne $data.steps) { [int]$data.steps } else { 1 }

    if ($steps -lt 1 -or $steps -gt 500) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{ error = 'steps must be between 1 and 500' }
      return
    }

    $gameOver = $false
    for ($i = 0; $i -lt $steps; $i++) {
      $state.Board = Step-LifeBoard -Board $state.Board -Width $state.Width -Height $state.Height -Wrap $state.Wrap
      $state.Generation++
      $gameOver = Test-BoardGameOver -Board $state.Board -Width $state.Width -Height $state.Height
      if ($gameOver) {
        break
      }
    }
    if ($gameOver) {
      Write-Host 'GAME OVER'
    }
    Write-PodeJsonResponse -Value (New-LifeStatePayload -State $state)
  }

  Add-PodeRoute -Method Post -Path '/api/toggle' -ScriptBlock {
    $state = Get-PodeState -Name 'life'
    $data = $WebEvent.Data

    $x = [int]$data.x
    $y = [int]$data.y

    if ($x -lt 0 -or $x -ge $state.Width -or $y -lt 0 -or $y -ge $state.Height) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{ error = 'cell coordinates are outside the board' }
      return
    }

    $state.Board[$y, $x] = -not $state.Board[$y, $x]

    Write-PodeJsonResponse -Value (New-LifeStatePayload -State $state)
  }

  Write-Host "Conway browser app is running at http://localhost:$serverPort"
}
