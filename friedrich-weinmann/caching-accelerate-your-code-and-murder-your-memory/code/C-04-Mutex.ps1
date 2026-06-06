# Failsafe
return

#----------------------------------------------------------------------------#
#                    Concurrent Access, Caches & Mutexes                     #
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

class PSFileCacheMutex {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	hidden [string] $Path
	hidden [int] $Depth

	PSFileCacheMutex([PSFNewFileSingle]$Path, [int]$Depth) {
		$this.Path = $Path
		$this.Depth = $Depth + 2 # 2 because Hashtable & CacheData
		New-Mutex -Name $this.GetMutexName()
		$data = $this.Read()
		$this.Write($data)
	}

	#region File Operations
	[hashtable]Read() {
		if (Test-Path -Path $this.Path) {
			Lock-Mutex -Name $this.GetMutexName()
			$data = Import-PSFClixml -Path $this.Path
			Unlock-Mutex -Name $this.GetMutexName()
			return $data
		}
		return @{ }
	}
	[void]Write([hashtable]$Data) {
		Lock-Mutex -Name $this.GetMutexName()
		$Data | Export-PSFClixml -Path $this.Path -Depth $this.Depth
		Unlock-Mutex -Name $this.GetMutexName()
	}
	[string]GetMutexName() {
		return "Cache-" + [convert]::ToBase64String(
			[System.Text.Encoding]::UTF8.GetBytes($this.Path)
		)
	}
	#endregion File Operations

	#region Set Values
	[void]Set([object]$Key, [object]$Value) {
		$data = $this.Read()
		
		$data[$Key] = [CacheData]::new($Key, $Value)

		# Handle Expired Entries
		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			$expired = $data.Values | Where-Object Timestamp -LT $limit
			foreach ($entry in $expired) {
				$data.Remove($entry.Key)
			}
		}

		# Handle Too Many Items
		if ($this.MaxItems -ge 1) {
			while ($data.Keys.Count -gt $this.MaxItems) {
				$oldest = $data.Values | Sort-Object Timestamp | Select-Object -First 1
				$data.Remove($oldest.Key)
			}
		}

		$this.Write($data)
	}
	#endregion Set Values

	#region Read Values
	[object]Get([object]$Key) {
		$data = $this.Read()
		$entry = $data[$Key]
		if ($null -eq $entry) {
			return $null
		}
		
		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			if ($entry.Timestamp -lt $limit) {
				$data.Remove($entry.Key)
				$this.Write($data)
				return $null
			}
		}

		return $entry.Value
	}
	#endregion Read Values
}

$cache = [PSFileCacheMutex]::new("C:\Temp\demo\mycache.mutex", 3)
$cache.Set(2, 2)
$cache.Get(2)
$cache.Set("Number", 1)

1..100 | Invoke-PSFRunspace {
	if (-not $global:cache) {
		$global:cache = [PSFileCacheMutex]::new("C:\Temp\demo\mycache.mutex", 3)
	}
	$old = $global:cache.Get("Number")
	$new = Get-Random -Minimum 10 -Maximum 99
	$global:cache.Set("Number", $new)
	[PSCustomObject]@{
		Number    = $_
		Old       = $old
		New       = $new
		Timestamp = Get-Date
	}
	Start-Sleep -Milliseconds 50
} | Sort-Object Timestamp

#-> Next: ???
code "$presentationRoot\D-01-Questions.ps1"