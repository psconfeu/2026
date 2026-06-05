@{
	Version = 1
	Tree = @{
		ZeroTrustAssessment = @{
			'Graph.DisableCache' = $true

			ThrottleLimit = @{
				Export = 8
				Tests = 12
			}

			'Tests.Timeout' = '7d'
		}

		# Logging
		'LoggingProvider.eventlog.MyEvents.Enabled' = $true

		'PSFramework.Logging.EventLog.MyEvents' = @{
			LogName = 'ZeroTrustAssessment'
			Source = 'Zero Trust Assessment PowerShell'
		}
	}
}