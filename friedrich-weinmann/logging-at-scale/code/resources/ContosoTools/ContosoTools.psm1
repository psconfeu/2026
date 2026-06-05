#region Excessive Details

#-> Runs once every cycle
$start_Event = {
	$newPath = Get-ConfigValue -Name Path
	if (-not $script:writer) {
		$stream = [System.IO.FileStream]::new($newPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
		$script:writer = [System.IO.StreamWriter]::new($stream)
		$script:currentPath = $newPath
		return
	}
	if ($newPath -eq $script:currentPath) { return }

	# Case: Path Changed
	$script:writer.Flush()
	$script:writer.Close()
	$script:writer.Dispose()

	$stream = [System.IO.FileStream]::new($newPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::Read)
	$script:writer = [System.IO.StreamWriter]::new($stream)
	$script:currentPath = $newPath
}

#-> Runs for every message
$message_Event = {
	param ($Message)
	if (-not $script:writer) { throw "No writer created - Verify configured path is valid!" }
	$script:writer.WriteLine("$($Message.Timestamp.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss.fff')) [$($Message.Level)] $($Message.LogMessage)")
}

#-> RUns at the end of every cycle
$end_Event = {
	if (-not $script:writer) { return }
	$script:writer.Flush()
}

#-> Runs only once when discarding the entire provider
$final_Event = {
	if (-not $script:writer) { return }
	$script:writer.Flush()
	$script:writer.Close()
	$script:writer.Dispose()
	$script:writer = $null
}
$configuration_Settings = {
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.FastFile.Path' -Value '' -Initialize -Validation string -Description 'Path to the file where logs are written to.'
}
#endregion Excessive Details

$paramRegisterPSFLoggingProvider = @{
	Name                       = "FastFile"
	Version2                   = $true
	ConfigurationRoot          = 'PSFramework.Logging.FastFile'
	InstanceProperties         = @('Path')
	StartEvent                 = $start_Event
	MessageEvent               = $message_Event
	EndEvent                   = $end_Event
	FinalEvent                 = $final_Event
	ConfigurationSettings      = $configuration_Settings
	ConfigurationDefaultValues = @{
		# Style = '%Message%'
	}
}

# Register the FastFile logging provider
Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider