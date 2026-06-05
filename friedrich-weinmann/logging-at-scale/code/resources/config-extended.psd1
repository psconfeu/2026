@{
	Version = 1
	Tree = @{
		'|GithubAction' = @{
			'!Condition' = 'EnvGithubAction'
			'LoggingProvider.console.con.Enabled' = $true
			'PSFramework.Logging.Console.con.Style' = '%Time% [%Level%] %Message%'
		}
		'|Other' = @{
			'!Condition' = '-not EnvGithubAction -and OSWindows'
			'LoggingProvider.eventlog.myscript.Enabled' = $true
			'PSFramework.Logging.EventLog.myscript' = @{
				LogName = 'PSFramework'
				Source = 'MyScript'
			}
		}
	}
	Include = @(
		"%stage%/settings.json"
	)
}