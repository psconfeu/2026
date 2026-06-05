@{
	Version = 1
	Tree = @{
		'LoggingProvider.eventlog.myscript.Enabled' = $true

		'PSFramework.Logging.EventLog.myscript' = @{
			LogName = 'PSFramework'
			Source = 'PSDemo_MyScript'
		}
	}
}