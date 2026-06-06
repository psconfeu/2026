# Failsafe
return

#----------------------------------------------------------------------------#
#                            Multiple File Cache                             #
#----------------------------------------------------------------------------#

class PSFileCache {
	[TimeSpan]$Lifetime
	[int]$MaxItems

	hidden [string] $Path
	hidden [int] $Depth

	PSFileCache([PSFDirectorySingle]$Path, [int]$Depth) {
		$this.Path = $Path
		$this.Depth = $Depth
	}

	[string]GetKeyPath([string]$Key) {
		$encoded = [convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Key))
		return Join-Path -Path $this.Path -ChildPath $encoded
	}

	#region Set Values
	[void]Set([string]$Key, [object]$Value) {
		# Handle Expired Entries
		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			Get-ChildItem -Path $this.Path | Where-Object LastWriteTime -LT $limit | Remove-Item
		}
		
		$filePath = $this.GetKeyPath($Key)
		$Value | Export-PSFClixml -Path $filePath

		# Handle Too Many Items
		if ($this.MaxItems -ge 1) {
			Get-ChildItem -LiteralPath $this.Path
			| Sort-Object LastWriteTime -Descending
			| Select-Object -Skip $this.MaxItems
			| Remove-Item
		}
	}
	#endregion Set Values

	#region Read Values
	[object]Get([string]$Key) {
		$filePath = $this.GetKeyPath($Key)
		$info = [System.IO.FileInfo]::new($filePath)
		if (-not $info.Exists) { return $null }

		if ($this.Lifetime.TotalSeconds -gt 0) {
			$limit = [DateTime]::now.Add($this.Lifetime.Negate())
			if ($info.LastWriteTime -lt $limit) {
				Remove-Item -LiteralPath $info.FullName -Force -ErrorAction SilentlyContinue
				return $null
			}
		}
		
		return Import-PSFClixml -Path $info.FullName -ErrorAction Stop
	}
	#endregion Read Values

	[string[]]List() {
		return Get-ChildItem -LiteralPath $this.Path | ForEach-Object {
			[System.Text.Encoding]::UTF8.GetString(
				[convert]::FromBase64String($_.Name)
			)
		}
	}
}

$cache = [PSFileCache]::new(".\cache", 3)
New-Item -Path .\cache -ItemType Directory
$cache = [PSFileCache]::new(".\cache", 3)
$cache.Get("Foo")
$cache.Set("Answer", 42)
$cache.Get("Answer")
$cache.Set("Foo", 1)
$cache.Get("Foo")
$cache.List()

Get-ChildItem -Path .\cache

#-> Next: Mutant Alert!
code "$presentationRoot\C-04-Mutex.ps1"