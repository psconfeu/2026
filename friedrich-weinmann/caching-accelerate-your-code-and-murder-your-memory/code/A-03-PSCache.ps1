# Failsafe
return

#----------------------------------------------------------------------------# 
#                                  PSCache                                   # 
#----------------------------------------------------------------------------# 

class CacheData {
	[object]$Key
	[object]$Value
	[DateTime]$Timestamp

	CacheData([object]$Key, [object]$Value) {
		$this.Key = $Key
		$this.Value = $Value
		$this.Timestamp = [datetime]::Now
	}
}

class PSCache {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	hidden [hashtable]$Data = @{}

	#region Set Values
	[void]Set([object]$Key, [object]$Value) {
		$this.Data[$Key] = [CacheData]::new($Key, $Value)

		# Handle Expired Entries
		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			$expired = $this.Data.Values | Where-Object Timestamp -LT $limit
			foreach ($entry in $expired) {
				$this.Data.Remove($entry.Key)
			}
		}

		if ($this.MaxItems -lt 1) { return }

		# Handle Too Many Items
		while ($this.Data.Keys.Count -gt $this.MaxItems) {
			$oldest = $this.Data.Values | Sort-Object Timestamp | Select-Object -First 1
			$this.Data.Remove($oldest.Key)
		}
	}
	#endregion Set Values

	#region Read Values
	[object]Get([object]$Key) {
		$entry = $this.Data[$Key]
		if ($null -eq $entry) {
			return $null
		}
		
		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			if ($entry.Timestamp -lt $limit) {
				$this.Data.Remove($entry.Key)
				return $null
			}
		}

		return $entry.Value
	}
	#endregion Read Values
}

$cache = [PSCache]::new()
$cache.MaxItems = 10
$cache.Lifetime = [timespan]::new(0, 0, 15)
1..50 | ForEach-Object { $cache.Set("$_", $_) }

$cache = [PSCache]::new()
$cache.MaxItems = 1000
$cache.Lifetime = [timespan]::new(0, 0, 15)
1..5000 | ForEach-Object { $cache.Set("$_", $_) }

#-> Next: Let's Fix This
code "$presentationRoot\A-04-Next.ps1"