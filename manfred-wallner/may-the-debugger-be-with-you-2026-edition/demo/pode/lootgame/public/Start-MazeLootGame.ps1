
function Start-MazeLootGame {
  <#
    .SYNOPSIS
        Starts the Maze Loot Game as a Pode web server.
    .DESCRIPTION
        Launches a local HTTP server (default port 8080) that serves a browser UI
        where players are selected and games are started interactively.
        Open http://localhost:<Port> in your browser after running.
    .PARAMETER Port
        TCP port for the Pode web server. Defaults to 8080.
    .EXAMPLE
        Start-MazeLootGame
        Start-MazeLootGame -Port 9090
    #>
  param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080
  )

  $podeScript = Join-Path $PSScriptRoot '..' 'lootgame_pode.ps1'
  if (-not (Test-Path -LiteralPath $podeScript)) {
    throw "Pode entry script not found: $podeScript"
  }

  & $podeScript -Port $Port
}
