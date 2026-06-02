
function Start-Looting {
  param(
    [string]$PlayerName,
    [System.Collections.Concurrent.ConcurrentQueue[string]]$Items,
    [System.Collections.Hashtable]$LiveScores,
    [System.Collections.Hashtable]$GameSettings
  )

  Start-ThreadJob -Name "$PlayerName's Quest" -StreamingHost $Host -ScriptBlock {
    param($Me, $Items, $LiveScores, $GameSettings)

    [runspace]::DefaultRunspace.Name = "QuestRunspace_$Me"

    Start-Sleep -Milliseconds (Get-Random -Minimum 40 -Maximum 80)
    $myItems = [System.Collections.ArrayList]::new()
    while ($Items.Count -gt 0) {
      $item = $null
      if ($Items.TryDequeue([ref]$item)) {
        $myItems.Add($item) | Out-Null
        if ($null -ne $LiveScores) {
          $LiveScores[$Me] = $myItems.Count
        }
      }

      $delayMs = 0
      if ($null -ne $GameSettings -and $GameSettings.ContainsKey('DelayMs')) {
        $candidate = 0
        if ([int]::TryParse([string]$GameSettings.DelayMs, [ref]$candidate)) {
          $delayMs = [Math]::Max(10, [Math]::Min(1000, $candidate))
        }
      }
      Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 30) # randomly delay players to make it a fair game
      Start-Sleep -Milliseconds $delayMs # delay per item to simulate work and allow for live score updates
    }
    @{
      Name      = $Me
      Items     = @($myItems)
      ItemCount = $myItems.Count
    }
  } -ArgumentList @($PlayerName, $Items, $LiveScores, $GameSettings)
}
