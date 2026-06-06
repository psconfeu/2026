# Failsafe
return

#----------------------------------------------------------------------------#
#                         Background-Refreshed Cache                         #
#----------------------------------------------------------------------------#

#-> Task Scheduler in your process
Register-PSFTaskEngineTask -Name Demo -ScriptBlock {
	$newValue = Get-Random -Minimum 10 -Maximum 99
	Set-PSFTaskEngineCache -Module MyDemo -Name Number -Value $newValue
} -Interval 15s
Get-PSFTaskEngineCache -Module MyDemo -Name Number
Disable-PSFTaskEngineTask -Name Demo

#-> Collectors Once Again
Set-PSFTaskEngineCache -Module MyDemo -Name Number -Lifetime 15s -Collector {
	Start-Sleep -Seconds 3
	Get-Random -Minimum 10 -Maximum 99
}
1..10 | Invoke-PSFRunspace {
	$start = Get-Date
	$number = Get-PSFTaskEngineCache -Module MyDemo -Name Number
	$end = Get-Date

	[PSCustomObject]@{
		ID       = $_
		Number   = $number
		Start    = $start.ToString('HH:mm:ss.fff')
		End      = $end.ToString('HH:mm:ss.fff')
		Duration = ($end - $start).TotalMilliseconds
	}
} | Sort-Object Start | Format-Table

#-> PSFCache & Background Refresh
$cache = New-PSFCache -Lifetime 1m
Register-PSFTaskEngineTask -Name DemoCache -ScriptBlock {
	param ($Cache)

	$cache["Number"] = Get-Random -Minimum 10 -Maximum 99
} -ArgumentList $cache -Interval 15s
$cache
$cache['Number']

#-> Next: Caching Meets User Experience. A Great Time Was To Be Had.
code "$presentationRoot\B-03-Caching-Meets-UX.ps1"