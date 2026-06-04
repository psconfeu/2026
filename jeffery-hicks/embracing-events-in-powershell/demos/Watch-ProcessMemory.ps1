#requires -version 5.1

<#
Watch for processes with high workingset values
#>

#polling interval in seconds
$Poll = 10
$query = "Select * from CIM_InstModification within $Poll where TargetInstance ISA 'Win32_Process' AND TargetInstance.WorkingSetSize>=$(900mb)"

$action = {
  #create a log file
  $logPath = 'C:\logs\HighMemLog.txt'
  "[$(Get-Date)] Computername = $($Event.SourceEventArgs.NewEvent.SourceInstance.CSName)" | Out-File -FilePath $logPath -Append
  "[$(Get-Date)] Process = $($Event.SourceEventArgs.NewEvent.SourceInstance.Name)" | Out-File -FilePath $logPath -Append
  "[$(Get-Date)] Command = $($Event.SourceEventArgs.NewEvent.SourceInstance.Commandline)" | Out-File -FilePath $logPath -Append
  "[$(Get-Date)] PID = $($Event.SourceEventArgs.NewEvent.SourceInstance.ProcessID)" | Out-File -FilePath $logPath -Append
  "[$(Get-Date)] WS(MB) = $([math]::Round($Event.SourceEventArgs.NewEvent.SourceInstance.WorkingSetSize/1MB,2))" | Out-File -FilePath $logPath -Append
  "[$(Get-Date)] $('*' * 60)" | Out-File -FilePath $logPath -Append

  #set a toast notification
  $Title = New-BTHeader -title "High Memory Alert"
  $msg = @"
Process = $($Event.SourceEventArgs.NewEvent.SourceInstance.Name)
PID = $($Event.SourceEventArgs.NewEvent.SourceInstance.ProcessID)
WS(MB) = $([math]::Round($Event.SourceEventArgs.NewEvent.SourceInstance.WorkingSetSize/1MB,2))
Date = $($event.TimeGenerated)
"@
  New-BurntToastNotification -Text $msg -AppLogo c:\scripts\mspowershell.png -Header $title
}

Register-CimIndicationEvent -Query $query -SourceIdentifier 'HighProcessMemory' -Action $action