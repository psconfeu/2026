# Failsafe
return

#----------------------------------------------------------------------------# 
#                                 Neighbours                                 # 
#----------------------------------------------------------------------------# 

<#
The Problem with Queues
Ordered Dictionary and its Keys
- Type
- Update
#>

#region Solution
class CacheData {
	[object]$Key
	[object]$Value
	[DateTime]$Timestamp

	[CacheData]$Next
	[CacheData]$Previous

	CacheData([object]$Key, [object]$Value) {
		$this.Key = $Key
		$this.Value = $Value
		$this.Timestamp = [datetime]::Now
	}
}

class PSCache {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	[CacheData]$Newest
	[CacheData]$Oldest

	hidden [hashtable]$Data = @{}

	#region Remove Entries
	hidden [void]RemoveEntry([CacheData]$Entry) {
		$previous = $Entry.Previous
		$next = $Entry.Next
		if ($null -ne $next) { $next.Previous = $previous }
		if ($null -ne $previous) { $previous.Next = $next }

		if ($this.Oldest -eq $Entry) { $this.Oldest = $next }
		if ($this.Newest -eq $Entry) { $this.Newest = $previous }

		$this.Data.Remove($Entry.Key)
	}
	#endregion Remove Entries

	#region Set Values
	[void]Set([object]$Key, [object]$Value) {
		#region First Entry
		if ($this.Data.Count -eq 0) {
			$entry = [CacheData]::new($Key, $Value)
			$this.Oldest = $entry
			$this.Newest = $entry
			$this.Data[$Key] = $entry
			return
		}
		#endregion First Entry

		# Remove old entry (if present)
		if ($this.Data[$Key]) {
			$this.RemoveEntry($this.Data[$Key])
		}

		# Add new entry to Hashtable
		$entry = [CacheData]::new($Key, $Value)
		$this.Data[$Key] = $entry

		# Update Order Linking
		$this.Newest.Next = $entry
		$entry.Previous = $this.Newest
		$this.Newest = $entry

		# Drain Excess Items
		while ($this.Data.Count -gt $this.MaxItems -and $this.MaxItems -gt 0) {
			$this.RemoveEntry($this.Oldest)
		}

		if ($this.Lifetime.TotalSeconds -le 0) { return }

		# Drain Expired Items
		$limit = [DateTime]::now.Add($this.Lifetime.Negate())
		while ($this.Oldest.Timestamp -lt $limit) {
			$this.RemoveEntry($this.Oldest)
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
				$this.RemoveEntry($entry)
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
#endregion Solution

#-> Next: Concurrency
code "$presentationRoot\B-01-PSFramework-Cache.ps1"