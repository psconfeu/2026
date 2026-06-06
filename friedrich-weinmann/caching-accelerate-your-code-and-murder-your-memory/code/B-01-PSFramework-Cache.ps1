# Failsafe
return

#----------------------------------------------------------------------------#
#                            PSFramework Caching                             #
#----------------------------------------------------------------------------#

#-> PSFCache
$cache = New-PSFCache -MaxItems 1000
1..5000 | ForEach-Object { $cache[$_] = $_ }
$cache.Count
$cache

#-> Concurrent
$cache = New-PSFCache -MaxItems 500
1..5000 | Invoke-PSFRunspace -ScriptBlock {
	$n = $_
	try {
		$cache[$_] = $_
		$delta = Get-Random -Minimum 10 -Maximum 50
		$old = $_ - $delta
		if ($cache[$old]) {
			$cache[$_] += $cache[$old]
			$cache.Remove($old)
		}
	}
	catch {
		Write-PSFMessage -Level Warning -Message "Failed on {0}" -StringValues $n -Target $n -ErrorRecord $_
	}
} -Variables @{ cache = $cache }
Get-PSFMessage -Level Warning
$cache
$cache.Count

#-> Expiration
$cache = New-PSFCache -Lifetime 15s
1..5 | ForEach-Object { $cache[$_] = $_ * 2 }
$cache
$cache[1]


# Collector
#------------

$cache = New-PSFCache -MaxItems 500 -TryDispose -Collector {
	Get-ChildItem -Path C:\Windows -Filter $_
}
$cache
$cache["e*"]
$cache["explorer.exe"]
$cache


#-> $this
$cache = New-PSFCache -MaxItems 500 -TryDispose -Collector {
	$_
	$this[($_ * 2)] = $_ * 2
}
$cache[2]
$cache

#-> Next: Background Characters
code "$presentationRoot\B-02-BackgroundRefresh.ps1"

#-> Did you mess up the timing, Fred?
code "$presentationRoot\C-01-Disk.ps1"