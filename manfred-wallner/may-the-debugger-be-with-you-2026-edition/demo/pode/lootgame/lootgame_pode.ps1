param(
	[ValidateRange(1024, 65535)]
	[int]$Port = 8080
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module Pode -ErrorAction Stop

# ---------------------------------------------------------------------------
# Pode server
# ---------------------------------------------------------------------------

$webPath = Join-Path $PSScriptRoot 'web'
if (-not (Test-Path -LiteralPath $webPath -PathType Container)) {
	throw "Missing web assets folder: $webPath"
}


# Pre-resolve paths before Start-PodeServer — $using: is not valid inside
# Pode's Invoke-PodeScriptBlock, but plain variables from the outer runspace are.
$helperScripts = Get-Item (Join-Path $PSScriptRoot 'private/*.ps1')

foreach ($script in $helperScripts) {
	. $script.FullName
}

Write-RunspaceThreadInfo -Purpose 'Main script runspace (starts Pode host)'

Start-PodeServer -Threads 2 -ScriptBlock {

	foreach ($script in $helperScripts) {
		Use-PodeScript -Path $script.FullName
	}

	Write-RunspaceThreadInfo -Purpose 'Pode server setup runspace (registers endpoints/routes)'

	$serverPort = $Port
	$allCharacters = Get-AvailableCharacters

	# Print Pode error logs to the host console.
	New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

	Add-PodeEndpoint -Address '*' -Port $serverPort -Protocol Http

	Add-PodeBodyParser -ContentType 'application/json' -ScriptBlock {
		param($body)
		if ([string]::IsNullOrWhiteSpace($body)) { return @{} }
		return ($body | ConvertFrom-Json -AsHashtable -Depth 32)
	}

	# Shared, thread-safe game state
	$gameState = [hashtable]::Synchronized(@{
			Status       = 'idle'
			Players      = @()
			TotalItems   = 0
			LootQueue    = $null
			Jobs         = $null
			Results      = @()
			LiveScores   = [hashtable]::Synchronized(@{})
			GameSettings = [hashtable]::Synchronized(@{ DelayMs = 20 })
		})
	Set-PodeState -Name 'loot' -Value $gameState

	# Keep track of runspaces already announced so each worker logs once.
	$announcedRunspaces = [hashtable]::Synchronized(@{})
	Set-PodeState -Name 'runspaceAnnouncements' -Value $announcedRunspaces

	Add-PodeMiddleware -Name 'announce-request-runspace' -ScriptBlock {
		$tracker = Get-PodeState -Name 'runspaceAnnouncements'
		$runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace
		$runspaceId = if ($null -ne $runspace) { $runspace.Id } else { '<none>' }

		if (-not $tracker.ContainsKey($runspaceId)) {
			$tracker[$runspaceId] = $true
			$threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
			Write-Host ('[debug-attach] runspaceId={0} threadId={1} purpose=Pode request worker runspace (serves HTTP requests)' -f $runspaceId, $threadId)
		}

		return $true
	}

	Add-PodeStaticRoute -Path '/' -Source $webPath -Defaults @('index.html')

	# ----- GET /api/characters ------------------------------------------------
	Add-PodeRoute -Method Get -Path '/api/characters' -ScriptBlock {
		Write-PodeJsonResponse -Value @{ characters = $using:allCharacters }
	}

	# ----- GET /api/status ----------------------------------------------------
	Add-PodeRoute -Method Get -Path '/api/status' -ScriptBlock {
		$state = Get-PodeState -Name 'loot'

		# Harvest completed jobs
		if ($state.Status -eq 'running' -and $null -ne $state.Jobs) {
			$pending = @($state.Jobs | Where-Object { $_.State -notin @('Completed', 'Failed') })
			if ($pending.Count -eq 0) {
				$results = Receive-Job $state.Jobs -AutoRemoveJob -Wait
				$sorted = @($results | Sort-Object -Property ItemCount -Descending)
				$state.Results = $sorted
				$state.Status = 'completed'
				$state.Jobs = $null
			}
		}

		$remaining = if ($null -ne $state.LootQueue) { $state.LootQueue.Count } else { 0 }

		# During a running game serve live per-player scores; once completed serve final results.
		$currentResults = if ($state.Status -eq 'running') {
			@($state.LiveScores.GetEnumerator() |
				Sort-Object -Property Value -Descending |
				ForEach-Object { @{ name = $_.Key; itemCount = $_.Value } })
		}
		else {
			@($state.Results | ForEach-Object { @{ name = $_.Name; itemCount = $_.ItemCount } })
		}

		Write-PodeJsonResponse -Value @{
			status         = $state.Status
			players        = @($state.Players)
			totalItems     = $state.TotalItems
			remainingItems = $remaining
			delayMs        = $state.GameSettings.DelayMs
			results        = $currentResults
		}
	}

	# ----- POST /api/speed ----------------------------------------------------
	Add-PodeRoute -Method Post -Path '/api/speed' -ScriptBlock {
		$state = Get-PodeState -Name 'loot'
		$data = $WebEvent.Data

		$delayMs = 0
		if (-not [int]::TryParse([string]$data.delayMs, [ref]$delayMs)) {
			Set-PodeResponseStatus -Code 400
			Write-PodeJsonResponse -Value @{ error = 'delayMs must be an integer' }
			return
		}

		if ($delayMs -lt 10 -or $delayMs -gt 1000) {
			Set-PodeResponseStatus -Code 400
			Write-PodeJsonResponse -Value @{ error = 'delayMs must be between 10 and 1000' }
			return
		}

		$state.GameSettings.DelayMs = $delayMs

		Write-PodeJsonResponse -Value @{ delayMs = $state.GameSettings.DelayMs }
	}

	# ----- POST /api/start ----------------------------------------------------
	Add-PodeRoute -Method Post -Path '/api/start' -ScriptBlock {
		$state = Get-PodeState -Name 'loot'
		$data = $WebEvent.Data

		if ($state.Status -eq 'running') {
			Set-PodeResponseStatus -Code 409
			Write-PodeJsonResponse -Value @{ error = 'A game is already running' }
			return
		}

		$players = @($data.players)
		if ($players.Count -eq 0) {
			Set-PodeResponseStatus -Code 400
			Write-PodeJsonResponse -Value @{ error = 'At least one player is required' }
			return
		}

		foreach ($p in $players) {
			if ($p -notin $using:allCharacters) {
				Set-PodeResponseStatus -Code 400
				Write-PodeJsonResponse -Value @{ error = "Unknown character: $p" }
				return
			}
		}

		# Build the loot queue
		$lootItems = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
		foreach ($item in (Get-AvailableItems)) {
			$lootItems.Enqueue($item)
		}
		$total = $lootItems.Count

		$state.Status = 'running'
		$state.Players = $players
		$state.TotalItems = $total
		$state.LootQueue = $lootItems
		$state.Results = @()
		$state.LiveScores.Clear()
		foreach ($player in $players) { $state.LiveScores[$player] = 0 }

		$jobs = foreach ($player in $players) {
			Start-Looting -PlayerName $player -Items $lootItems -LiveScores $state.LiveScores -GameSettings $state.GameSettings
		}
		$state.Jobs = @($jobs)

		Write-PodeJsonResponse -Value @{
			status     = 'running'
			players    = $players
			delayMs    = $state.GameSettings.DelayMs
			totalItems = $total
		}
	}

	# ----- POST /api/reset ----------------------------------------------------
	Add-PodeRoute -Method Post -Path '/api/reset' -ScriptBlock {
		$state = Get-PodeState -Name 'loot'

		if ($null -ne $state.Jobs) {
			$state.Jobs | Remove-Job -Force -ErrorAction SilentlyContinue
		}

		$state.Status = 'idle'
		$state.Players = @()
		$state.TotalItems = 0
		$state.LootQueue = $null
		$state.Jobs = $null
		$state.Results = @()
		$state.LiveScores.Clear()

		Write-PodeJsonResponse -Value @{ status = 'idle' }
	}

	Write-Host "Maze Loot Game is running at http://localhost:$serverPort"
}
