function New-WindowsServerDiagnosticsLoadingComponent {
	param(
		[string]$Title,
		[string]$Text
	)

	New-UDCard -Title $Title -Content {
		New-UDTypography -Text $Text -Variant 'body1' -GutterBottom
		New-UDAlert -Severity 'info' -Title 'Loading' -Text 'The page is gathering live diagnostics from this server.' -Dense
	}
}

$overviewPage = New-UDPage -Name 'Overview' -Content {
	New-UDDynamic -Id 'wsd-overview' -AutoRefresh -AutoRefreshInterval 30 -LoadingComponent {
		New-WindowsServerDiagnosticsLoadingComponent -Title 'Loading overview' -Text 'Collecting CPU, memory, uptime, reboot, and storage data.'
	} -Content {
		try {
			Import-Module PowerShellUniversal.WindowsServerDiagnostics -ErrorAction Stop
			$snapshot = Get-PSUWindowsServerDiagnostics -MaxEvents 100
			$cpuPercent = if ($null -ne $snapshot.CpuUsage.PercentProcessorTime) {
				[double]$snapshot.CpuUsage.PercentProcessorTime
			}
			else {
				0
			}

			$cpuChartData = @(
				[pscustomobject]@{ Segment = 'Used'; Value = [math]::Round($cpuPercent, 2) }
				[pscustomobject]@{ Segment = 'Idle'; Value = [math]::Round((100 - $cpuPercent), 2) }
			)

			$memoryChartData = @(
				[pscustomobject]@{ Segment = 'Used'; Value = [double]$snapshot.MemoryUsage.UsedGB }
				[pscustomobject]@{ Segment = 'Free'; Value = [double]$snapshot.MemoryUsage.FreeGB }
			)

			$systemDriveUsed = [math]::Round(([double]$snapshot.SystemDrive.SizeGB - [double]$snapshot.SystemDrive.FreeGB), 2)
			$systemDriveChartData = @(
				[pscustomobject]@{ Segment = 'Used'; Value = $systemDriveUsed }
				[pscustomobject]@{ Segment = 'Free'; Value = [double]$snapshot.SystemDrive.FreeGB }
			)

			$rebootSeverity = if ($snapshot.PendingReboot.PendingReboot) { 'warning' } else { 'success' }
			$rebootTitle = if ($snapshot.PendingReboot.PendingReboot) { 'Pending reboot detected' } else { 'No reboot pending' }
			$rebootText = if ($snapshot.PendingReboot.PendingReboot) {
				'Reasons: ' + (($snapshot.PendingReboot.Reasons | Sort-Object) -join ', ')
			}
			else {
				'The server does not currently report a pending reboot condition.'
			}

			$systemDetails = @(
				[pscustomobject]@{ Property = 'Host name'; Value = $snapshot.HostName }
				[pscustomobject]@{ Property = 'Operating system'; Value = $snapshot.OperatingSystem.Caption }
				[pscustomobject]@{ Property = 'Version'; Value = $snapshot.OperatingSystem.Version }
				[pscustomobject]@{ Property = 'Build number'; Value = $snapshot.OperatingSystem.BuildNumber }
				[pscustomobject]@{ Property = 'Architecture'; Value = $snapshot.OperatingSystem.Architecture }
				[pscustomobject]@{ Property = 'System drive'; Value = $snapshot.SystemDrive.Drive }
				[pscustomobject]@{ Property = 'Collected at'; Value = ([datetime]$snapshot.CollectedAt).ToString('yyyy-MM-dd HH:mm:ss') }
			)

			New-UDTypography -Text 'Windows Server Diagnostics' -Variant 'h4' -GutterBottom
			New-UDTypography -Text "Snapshot taken at $(([datetime]$snapshot.CollectedAt).ToString('yyyy-MM-dd HH:mm:ss'))" -Variant 'body1' -GutterBottom

			New-UDGrid -Container -Content {
				New-UDGrid -Item -SmallSize 12 -MediumSize 6 -LargeSize 3 -Content {
					New-UDCard -Title 'Host' -Content {
						New-UDTypography -Text $snapshot.HostName -Variant 'h5' -GutterBottom
						New-UDTypography -Text $snapshot.OperatingSystem.Caption -Variant 'body2'
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 6 -LargeSize 3 -Content {
					New-UDCard -Title 'Uptime' -Content {
						New-UDTypography -Text (("{0} days {1} hours {2} minutes" -f $snapshot.Uptime.Days, $snapshot.Uptime.Hours, $snapshot.Uptime.Minutes)) -Variant 'h5' -GutterBottom
						New-UDTypography -Text "Last boot: $(([datetime]$snapshot.Uptime.LastBootUpTime).ToString('yyyy-MM-dd HH:mm'))" -Variant 'body2'
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 6 -LargeSize 3 -Content {
					New-UDCard -Title 'CPU' -Content {
						New-UDTypography -Text ("{0}%" -f ([math]::Round($cpuPercent, 2))) -Variant 'h4' -GutterBottom
						New-UDTypography -Text "Source: $($snapshot.CpuUsage.Source)" -Variant 'body2'
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 6 -LargeSize 3 -Content {
					New-UDCard -Title 'Memory' -Content {
						New-UDTypography -Text ("{0}% used" -f $snapshot.MemoryUsage.PercentUsed) -Variant 'h4' -GutterBottom
						New-UDTypography -Text ("{0} GB used of {1} GB" -f $snapshot.MemoryUsage.UsedGB, $snapshot.MemoryUsage.TotalGB) -Variant 'body2'
					}
				}

				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -LargeSize 4 -Content {
					New-UDCard -Title 'CPU Utilization' -Content {
						New-UDElement -Tag 'div' -Attributes @{ style = @{ height = '200px' } } -Content {
							New-UDChartJS -Type 'doughnut' -Data $cpuChartData -DataProperty 'Value' -LabelProperty 'Segment' -BackgroundColor @('#d9534f', '#5cb85c') -HoverBackgroundColor @('#d9534f', '#5cb85c') -Id 'wsd-cpu-chart'
						}
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -LargeSize 4 -Content {
					New-UDCard -Title 'Memory Allocation' -Content {
						New-UDElement -Tag 'div' -Attributes @{ style = @{ height = '200px' } } -Content {
							New-UDChartJS -Type 'doughnut' -Data $memoryChartData -DataProperty 'Value' -LabelProperty 'Segment' -BackgroundColor @('#f0ad4e', '#5bc0de') -HoverBackgroundColor @('#f0ad4e', '#5bc0de') -Id 'wsd-memory-chart'
						}
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -LargeSize 4 -Content {
					New-UDCard -Title 'System Drive' -Content {
						New-UDElement -Tag 'div' -Attributes @{ style = @{ height = '200px' } } -Content {
							New-UDChartJS -Type 'doughnut' -Data $systemDriveChartData -DataProperty 'Value' -LabelProperty 'Segment' -BackgroundColor @('#c9302c', '#428bca') -HoverBackgroundColor @('#c9302c', '#428bca') -Id 'wsd-drive-chart'
						}
						New-UDTypography -Text ("Drive {0}: {1}% free" -f $snapshot.SystemDrive.Drive, $snapshot.SystemDrive.PercentFree) -Variant 'body2' -GutterBottom
						New-UDTypography -Text ("{0} GB free of {1} GB" -f $snapshot.SystemDrive.FreeGB, $snapshot.SystemDrive.SizeGB) -Variant 'body2'
					}
				}

				New-UDGrid -Item -SmallSize 12 -MediumSize 12 -LargeSize 5 -Content {
					New-UDAlert -Severity $rebootSeverity -Title $rebootTitle -Text $rebootText -Dense
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 12 -LargeSize 7 -Content {
					New-UDCard -Title 'System Details' -Content {
						$detailColumns = @(
							New-UDTableColumn -Property 'Property' -Title 'Property'
							New-UDTableColumn -Property 'Value' -Title 'Value'
						)
						New-UDTable -Data $systemDetails -Columns $detailColumns -Id 'wsd-system-details'
					}
				}
			}
		}
		catch {
			New-UDAlert -Severity 'error' -Title 'Diagnostics snapshot failed' -Text $_.Exception.Message
		}
	}
}

$servicesPage = New-UDPage -Name 'Services and Events' -Content {
	New-UDDynamic -Id 'wsd-services-events' -AutoRefresh -AutoRefreshInterval 60 -LoadingComponent {
		New-WindowsServerDiagnosticsLoadingComponent -Title 'Loading operational health' -Text 'Collecting service state and recent Windows error events.'
	} -Content {
		try {
			Import-Module PowerShellUniversal.WindowsServerDiagnostics -ErrorAction Stop
			$snapshot = Get-PSUWindowsServerDiagnostics -MaxEvents 100

			$serviceColumns = @(
				New-UDTableColumn -Property 'DisplayName' -Title 'Display Name' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'Name' -Title 'Service Name' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'State' -Title 'State' -ShowSort
				New-UDTableColumn -Property 'StartName' -Title 'Run As' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'ExitCode' -Title 'Exit Code' -ShowSort
			)

			$eventColumns = @(
				New-UDTableColumn -Property 'TimeCreated' -Title 'Time Created' -ShowSort -SortType 'datetime'
				New-UDTableColumn -Property 'LevelDisplayName' -Title 'Level' -ShowSort
				New-UDTableColumn -Property 'LogName' -Title 'Log' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'ProviderName' -Title 'Source' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'Id' -Title 'Event Id' -ShowSort
				New-UDTableColumn -Property 'Message' -Title 'Message' -Width 500 -Truncate -IncludeInSearch
			)

			$serviceAlertSeverity = if ($snapshot.StoppedAutomaticServices.Count -gt 0) { 'warning' } else { 'success' }
			$serviceAlertTitle = if ($snapshot.StoppedAutomaticServices.Count -gt 0) {
				"$($snapshot.StoppedAutomaticServices.Count) automatic services are stopped"
			}
			else {
				'No stopped automatic services detected'
			}

			$eventAlertSeverity = if ($snapshot.RecentEvents.Count -gt 0) { 'warning' } else { 'success' }
			$eventAlertTitle = if ($snapshot.RecentEvents.Count -gt 0) {
				"$($snapshot.RecentEvents.Count) recent critical or error events"
			}
			else {
				'No recent critical or error events in the selected window'
			}

			New-UDTypography -Text 'Operational health' -Variant 'h4' -GutterBottom
			New-UDTypography -Text "Using the last 24 hours of Windows event data. Refreshed at $(([datetime]$snapshot.CollectedAt).ToString('yyyy-MM-dd HH:mm:ss'))" -Variant 'body1' -GutterBottom

			New-UDGrid -Container -Content {
				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDAlert -Severity $serviceAlertSeverity -Title $serviceAlertTitle -Text 'Automatic services should usually be running. Review anything listed below before it becomes user-visible.' -Dense
				}
				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDCard -Title 'Stopped Automatic Services' -Content {
						New-UDTable -Data $snapshot.StoppedAutomaticServices -Columns $serviceColumns -ShowSearch -ShowSort -Paging -PageSize 10 -Id 'wsd-stopped-services'
					}
				}

				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDAlert -Severity $eventAlertSeverity -Title $eventAlertTitle -Text 'This view focuses on System and Application log entries at error and critical levels.' -Dense
				}
				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDCard -Title 'Recent Error and Critical Events' -Content {
						New-UDTable -Data $snapshot.RecentEvents -Columns $eventColumns -ShowSearch -ShowSort -Paging -PageSize 10 -Id 'wsd-recent-events'
					}
				}
			}
		}
		catch {
			New-UDAlert -Severity 'error' -Title 'Failed to load service and event data' -Text $_.Exception.Message
		}
	}
}

$iisPage = New-UDPage -Name 'IIS' -Content {
	New-UDDynamic -Id 'wsd-iis' -AutoRefresh -AutoRefreshInterval 60 -LoadingComponent {
		New-WindowsServerDiagnosticsLoadingComponent -Title 'Loading IIS inventory' -Text 'Collecting website, binding, and application pool details.'
	} -Content {
		try {
			Import-Module PowerShellUniversal.WindowsServerDiagnostics -ErrorAction Stop
			$snapshot = Get-PSUWindowsServerDiagnostics -MaxEvents 50

			New-UDTypography -Text 'IIS inventory' -Variant 'h4' -GutterBottom
			New-UDTypography -Text "Refreshed at $(([datetime]$snapshot.CollectedAt).ToString('yyyy-MM-dd HH:mm:ss'))" -Variant 'body1' -GutterBottom

			if (-not $snapshot.Iis.Installed) {
				New-UDAlert -Severity 'info' -Title 'IIS is not installed' -Text 'No IIS role indicators were detected on this server.'
				return
			}

			if (-not $snapshot.Iis.ModuleAvailable) {
				New-UDAlert -Severity 'warning' -Title 'IIS detected but WebAdministration is unavailable' -Text 'Install or enable the WebAdministration module to populate site and application pool details.'
				return
			}

			if ($snapshot.Iis.Error) {
				New-UDAlert -Severity 'error' -Title 'IIS inventory collection failed' -Text $snapshot.Iis.Error
				return
			}

			$siteRows = @($snapshot.Iis.Sites | ForEach-Object {
				[pscustomobject]@{
					Name = $_.Name
					State = $_.State
					Id = $_.Id
					PhysicalPath = $_.PhysicalPath
					Bindings = ($_.Bindings | ForEach-Object { "$($_.Protocol): $($_.BindingInformation)" }) -join '; '
				}
			})

			$appPoolRows = @($snapshot.Iis.AppPools | ForEach-Object {
				[pscustomobject]@{
					Name = $_.Name
					State = $_.State
					AutoStart = $_.AutoStart
					ManagedRuntimeVersion = $_.ManagedRuntimeVersion
					ManagedPipelineMode = $_.ManagedPipelineMode
				}
			})

			$siteColumns = @(
				New-UDTableColumn -Property 'Name' -Title 'Site' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'State' -Title 'State' -ShowSort
				New-UDTableColumn -Property 'Id' -Title 'Id' -ShowSort
				New-UDTableColumn -Property 'PhysicalPath' -Title 'Physical Path' -IncludeInSearch
				New-UDTableColumn -Property 'Bindings' -Title 'Bindings' -Width 500 -Truncate
			)

			$appPoolColumns = @(
				New-UDTableColumn -Property 'Name' -Title 'App Pool' -ShowSort -IncludeInSearch
				New-UDTableColumn -Property 'State' -Title 'State' -ShowSort
				New-UDTableColumn -Property 'AutoStart' -Title 'Auto Start' -ShowSort
				New-UDTableColumn -Property 'ManagedRuntimeVersion' -Title 'Runtime' -ShowSort
				New-UDTableColumn -Property 'ManagedPipelineMode' -Title 'Pipeline Mode' -ShowSort
			)

			New-UDGrid -Container -Content {
				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -Content {
					New-UDCard -Title 'Sites' -Content {
						New-UDTypography -Text $siteRows.Count -Variant 'h3'
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -Content {
					New-UDCard -Title 'Application Pools' -Content {
						New-UDTypography -Text $appPoolRows.Count -Variant 'h3'
					}
				}
				New-UDGrid -Item -SmallSize 12 -MediumSize 4 -Content {
					New-UDCard -Title 'Module Status' -Content {
						New-UDTypography -Text 'WebAdministration available' -Variant 'body1'
					}
				}

				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDCard -Title 'Web Sites' -Content {
						New-UDTable -Data $siteRows -Columns $siteColumns -ShowSearch -ShowSort -Paging -PageSize 10 -Id 'wsd-iis-sites'
					}
				}
				New-UDGrid -Item -SmallSize 12 -Content {
					New-UDCard -Title 'Application Pools' -Content {
						New-UDTable -Data $appPoolRows -Columns $appPoolColumns -ShowSearch -ShowSort -Paging -PageSize 10 -Id 'wsd-iis-app-pools'
					}
				}
			}
		}
		catch {
			New-UDAlert -Severity 'error' -Title 'Failed to load IIS inventory' -Text $_.Exception.Message
		}
	}
}

New-UDApp -Title 'Windows Server Diagnostics' -Pages @($overviewPage, $servicesPage, $iisPage) -NavigationLayout 'Permanent'
