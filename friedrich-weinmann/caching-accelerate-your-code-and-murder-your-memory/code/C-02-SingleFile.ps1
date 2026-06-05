# Failsafe
return

#----------------------------------------------------------------------------#
#                             Single File Cache                              #
#----------------------------------------------------------------------------#

# Variant 1: Disk-Held
#-----------------------

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

class PSFileCache {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	hidden [string] $Path
	hidden [int] $Depth

	PSFileCache([PSFNewFileSingle]$Path, [int]$Depth) {
		$this.Path = $Path
		$this.Depth = $Depth + 2 # 2 because Hashtable & CacheData
		$this.Read() | Export-PSFClixml -Path $Path -Depth ($Depth + 2) -ErrorAction Stop
	}

	#region File Operations
	[hashtable]Read() {
		if (Test-Path -Path $this.Path) {
			return Import-PSFClixml -Path $this.Path
		}
		return @{ }
	}
	[void]Write([hashtable]$Data) {
		$Data | Export-PSFClixml -Path $this.Path -Depth $this.Depth
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

		$data | Export-PSFClixml -Path $this.Path -Depth $this.Depth
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
$cache = [PSFileCache]::new(".\file.cache", 5)
$cache.MaxItems = 10
$cache.Lifetime = '00:00:15'
$cache.Get("Foo")
$cache.Set("Answer", 42)
$cache.Get("Answer")
Get-ChildItem
1..20 | ForEach-Object { $cache.Set($_, $_) }
Get-ChildItem
$cache.Get(5)
$cache.Get(15)

# Variant 2: Memory-Held, Flush on Demand
#------------------------------------------

class PSFileCache2 {
	[TimeSpan]$Lifetime
	[int]$MaxItems
	[bool]$AutoFlush

	hidden [hashtable]$Data = @{}

	hidden [string] $Path
	hidden [int] $Depth

	PSFileCache2([PSFNewFileSingle]$Path, [int]$Depth) {
		$this.Path = $Path
		$this.Depth = $Depth + 2 # 2 because Hashtable & CacheData
		$this.Read()
	}

	#region File Operations
	[hashtable]Read() {
		if (Test-Path -Path $this.Path) {
			return Import-PSFClixml -Path $this.Path
		}
		return @{ }
	}
	[void]Flush() {
		$this.Data | Export-PSFClixml -Path $this.Path -Depth $this.Depth
	}
	#endregion File Operations

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

		# Handle Too Many Items
		if ($this.MaxItems -ge 1) {
			while ($this.Data.Keys.Count -gt $this.MaxItems) {
				$oldest = $this.Data.Values | Sort-Object Timestamp | Select-Object -First 1
				$this.Data.Remove($oldest.Key)
			}
		}

		if ($this.AutoFlush) {
			$this.Flush()
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
				if ($this.AutoFlush) {
					$this.Flush()
				}
				return $null
			}
		}

		return $entry.Value
	}
	#endregion Read Values
}

$cache = [PSFileCache2]::new(".\file2.cache", 5)
$cache.MaxItems = 10
$cache.Lifetime = '00:00:15'
$cache.Get("Foo")
$cache.Set("Answer", 42)
$cache.Get("Answer")
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'
1..20 | ForEach-Object { $cache.Set($_, $_) }
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'
$cache.Get(5)
$cache.Get(15)
$cache.Flush()
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'

Remove-Item .\file2.cache
$cache2 = [PSFileCache2]::new(".\file2.cache", 5)
$cache2.AutoFlush = $true
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'
1..20 | ForEach-Object { $cache2.Set($_, $_) }
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'

# Variant 3: Memory-Held, Async Flush
class PSFileCacheAsync {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	hidden [hashtable]$Data = @{}

	hidden [string] $Path
	hidden [int] $Depth

	PSFileCacheAsync([PSFNewFileSingle]$Path, [int]$Depth) {
		$this.Path = $Path
		$this.Depth = $Depth + 2 # 2 because Hashtable & CacheData
		$this.Read()
	}

	#region File Operations
	[hashtable]Read() {
		if (Test-Path -Path $this.Path) {
			return Import-PSFClixml -Path $this.Path
		}
		return @{ }
	}
	[void]Flush() {
		$this.Data | Export-PSFClixml -Path $this.Path -Depth $this.Depth
	}
	[void]FlushAsync() {
		Register-PSFTaskEngineTask -Name "CacheSync-$($this.Path)-$(Get-Random)" -Once -ScriptBlock {
			param ($Cache)
			$Cache.Flush()
		} -ArgumentList $this
	}
	#endregion File Operations

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

		# Handle Too Many Items
		if ($this.MaxItems -ge 1) {
			while ($this.Data.Keys.Count -gt $this.MaxItems) {
				$oldest = $this.Data.Values | Sort-Object Timestamp | Select-Object -First 1
				$this.Data.Remove($oldest.Key)
			}
		}

		$this.FlushAsync()
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
				$this.FlushAsync()
				return $null
			}
		}

		return $entry.Value
	}
	#endregion Read Values
}

$cache3 = [PSFileCacheAsync]::new(".\fileAsync.cache", 5)
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'
1..20 | ForEach-Object { $cache3.Set($_, $_) }
Get-ChildItem | Select-PSFObject Name, Length, 'LastWriteTime.ToString("HH:mm:ss.fff") as LastWriteTime'

#-> Next: Spreading Out
code "$presentationRoot\C-03-MultiFile.ps1"