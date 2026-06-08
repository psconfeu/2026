function Get-PSUWindowsServerHostName {
	[CmdletBinding()]
	param()

	[System.Net.Dns]::GetHostName()
}

function Get-PSUWindowsServerOperatingSystem {
	[CmdletBinding()]
	param()

	$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem

	[pscustomobject]@{
		Caption        = $operatingSystem.Caption
		Version        = $operatingSystem.Version
		BuildNumber    = $operatingSystem.BuildNumber
		Architecture   = $operatingSystem.OSArchitecture
		InstallDate    = $operatingSystem.InstallDate
		LastBootUpTime = $operatingSystem.LastBootUpTime
		SerialNumber   = $operatingSystem.SerialNumber
		RegisteredUser = $operatingSystem.RegisteredUser
		Organization   = $operatingSystem.Organization
	}
}

function Get-PSUWindowsServerUptime {
	[CmdletBinding()]
	param()

	$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
	$uptime = (Get-Date) - $operatingSystem.LastBootUpTime

	[pscustomobject]@{
		LastBootUpTime = $operatingSystem.LastBootUpTime
		Days           = [math]::Floor($uptime.TotalDays)
		Hours          = $uptime.Hours
		Minutes        = $uptime.Minutes
		Seconds        = $uptime.Seconds
		TotalDays      = [math]::Round($uptime.TotalDays, 2)
	}
}

function Get-PSUWindowsServerCpuUsage {
	[CmdletBinding()]
	param()

	$cpuUsage = $null
	$source = 'Get-Counter'

	try {
		$counter = Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
		$cpuUsage = [math]::Round($counter.CounterSamples[0].CookedValue, 2)
	}
	catch {
		$source = 'Win32_Processor'
		$processors = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue

		if ($processors) {
			$cpuUsage = [math]::Round((($processors | Measure-Object -Property LoadPercentage -Average).Average), 2)
		}
	}

	[pscustomobject]@{
		PercentProcessorTime = $cpuUsage
		Source               = $source
		SampleTime           = Get-Date
	}
}

function Get-PSUWindowsServerMemoryUsage {
	[CmdletBinding()]
	param()

	$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
	$totalBytes = [double]$operatingSystem.TotalVisibleMemorySize * 1KB
	$freeBytes = [double]$operatingSystem.FreePhysicalMemory * 1KB
	$usedBytes = $totalBytes - $freeBytes
	$percentUsed = if ($totalBytes -gt 0) {
		[math]::Round(($usedBytes / $totalBytes) * 100, 2)
	}
	else {
		$null
	}

	[pscustomobject]@{
		TotalGB     = [math]::Round($totalBytes / 1GB, 2)
		UsedGB      = [math]::Round($usedBytes / 1GB, 2)
		FreeGB      = [math]::Round($freeBytes / 1GB, 2)
		PercentUsed = $percentUsed
	}
}

function Get-PSUWindowsServerSystemDrive {
	[CmdletBinding()]
	param()

	$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
	$drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = '$($operatingSystem.SystemDrive)'"

	$usedBytes = $drive.Size - $drive.FreeSpace
	$percentFree = if ($drive.Size -gt 0) {
		[math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)
	}
	else {
		$null
	}

	[pscustomobject]@{
		Drive       = $drive.DeviceID
		VolumeName  = $drive.VolumeName
		SizeGB      = [math]::Round($drive.Size / 1GB, 2)
		UsedGB      = [math]::Round($usedBytes / 1GB, 2)
		FreeGB      = [math]::Round($drive.FreeSpace / 1GB, 2)
		PercentFree = $percentFree
	}
}

function Get-PSUWindowsServerPendingReboot {
	[CmdletBinding()]
	param()

	$reasons = [System.Collections.Generic.List[string]]::new()

	if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
		$reasons.Add('ComponentBasedServicing')
	}

	if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
		$reasons.Add('WindowsUpdate')
	}

	$sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
	if ($sessionManager.PendingFileRenameOperations) {
		$reasons.Add('PendingFileRenameOperations')
	}

	$activeComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -ErrorAction SilentlyContinue).ComputerName
	$pendingComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -ErrorAction SilentlyContinue).ComputerName
	if ($activeComputerName -and $pendingComputerName -and $activeComputerName -ne $pendingComputerName) {
		$reasons.Add('ComputerRenamePending')
	}

	[pscustomobject]@{
		PendingReboot = $reasons.Count -gt 0
		Reasons       = @($reasons)
	}
}

function Get-PSUWindowsServerStoppedAutomaticService {
	[CmdletBinding()]
	param()

	Get-CimInstance -ClassName Win32_Service -Filter "StartMode = 'Auto' AND State <> 'Running'" |
		Sort-Object -Property DisplayName |
		Select-Object Name, DisplayName, State, StartMode, StartName, ExitCode
}

function Get-PSUWindowsServerRecentEvent {
	[CmdletBinding()]
	param(
		[datetime]$StartTime = (Get-Date).AddDays(-1),

		[ValidateRange(1, 500)]
		[int]$MaxEvents = 50
	)

	$events = Get-WinEvent -FilterHashtable @{
		LogName   = @('System', 'Application')
		Level     = @(1, 2)
		StartTime = $StartTime
	} -MaxEvents $MaxEvents -ErrorAction SilentlyContinue |
		Sort-Object -Property TimeCreated -Descending

	$events |
		Select-Object -First $MaxEvents |
		Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName, MachineName, Message
}

function Get-PSUWindowsServerIisInventory {
	[CmdletBinding()]
	param()

	$webAdministration = Get-Module -ListAvailable -Name WebAdministration -ErrorAction SilentlyContinue
	$iisRegistry = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\InetStp' -ErrorAction SilentlyContinue
	$w3svc = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
	$iisInstalled = ($null -ne $webAdministration) -or ($null -ne $iisRegistry) -or ($null -ne $w3svc)

	if (-not $iisInstalled) {
		return [pscustomobject]@{
			Installed       = $false
			ModuleAvailable = $false
			Sites           = @()
			AppPools        = @()
		}
	}

	if (-not $webAdministration) {
		return [pscustomobject]@{
			Installed       = $true
			ModuleAvailable = $false
			Sites           = @()
			AppPools        = @()
		}
	}

	try {
		Import-Module WebAdministration -ErrorAction Stop

		$sites = @(Get-Website | Sort-Object -Property Name | ForEach-Object {
			[pscustomobject]@{
				Name         = $_.Name
				Id           = $_.Id
				State        = $_.State
				PhysicalPath = $_.PhysicalPath
				Bindings     = @($_.Bindings.Collection | ForEach-Object {
					[pscustomobject]@{
						Protocol           = $_.Protocol
						BindingInformation = $_.BindingInformation
					}
				})
			}
		})

		$appPools = @(Get-ChildItem -Path IIS:\AppPools | Sort-Object -Property Name | ForEach-Object {
			$appPoolState = $null

			try {
				$appPoolState = (Get-WebAppPoolState -Name $_.Name -ErrorAction Stop).Value
			}
			catch {
				$appPoolState = $null
			}

			[pscustomobject]@{
				Name                  = $_.Name
				State                 = $appPoolState
				AutoStart             = $_.AutoStart
				ManagedRuntimeVersion = $_.ManagedRuntimeVersion
				ManagedPipelineMode   = $_.ManagedPipelineMode
			}
		})

		[pscustomobject]@{
			Installed       = $true
			ModuleAvailable = $true
			Sites           = $sites
			AppPools        = $appPools
		}
	}
	catch {
		[pscustomobject]@{
			Installed       = $true
			ModuleAvailable = $true
			Error           = $_.Exception.Message
			Sites           = @()
			AppPools        = @()
		}
	}
}

function Get-PSUWindowsServerDiagnostics {
	[CmdletBinding()]
	param(
		[datetime]$EventStartTime = (Get-Date).AddDays(-1),

		[ValidateRange(1, 500)]
		[int]$MaxEvents = 50
	)

	[pscustomobject]@{
		CollectedAt              = Get-Date
		HostName                 = Get-PSUWindowsServerHostName
		OperatingSystem          = Get-PSUWindowsServerOperatingSystem
		Uptime                   = Get-PSUWindowsServerUptime
		CpuUsage                 = Get-PSUWindowsServerCpuUsage
		MemoryUsage              = Get-PSUWindowsServerMemoryUsage
		SystemDrive              = Get-PSUWindowsServerSystemDrive
		PendingReboot            = Get-PSUWindowsServerPendingReboot
		StoppedAutomaticServices = @(Get-PSUWindowsServerStoppedAutomaticService)
		RecentEvents             = @(Get-PSUWindowsServerRecentEvent -StartTime $EventStartTime -MaxEvents $MaxEvents)
		Iis                      = Get-PSUWindowsServerIisInventory
	}
}

Export-ModuleMember -Function @(
	'Get-PSUWindowsServerHostName',
	'Get-PSUWindowsServerOperatingSystem',
	'Get-PSUWindowsServerUptime',
	'Get-PSUWindowsServerCpuUsage',
	'Get-PSUWindowsServerMemoryUsage',
	'Get-PSUWindowsServerSystemDrive',
	'Get-PSUWindowsServerPendingReboot',
	'Get-PSUWindowsServerStoppedAutomaticService',
	'Get-PSUWindowsServerRecentEvent',
	'Get-PSUWindowsServerIisInventory',
	'Get-PSUWindowsServerDiagnostics'
)
