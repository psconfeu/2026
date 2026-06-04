return 'This is a demo script file'

#region CimIndication events

Get-CimClass -ClassName __Instance*Event

$Computername = $env:COMPUTERNAME

#region basic query

# polling
# ISA
$query = "Select * from __InstanceCreationEvent within 10 Where TargetInstance ISA 'win32_process'"

# help Register-CimIndicationEvent
#watch for the next new process
$paramHash = @{
    Query            = $query
    ComputerName     = $Computername
    MessageData      = 'A new process was detected'
    MaxTriggerCount  = 1
    SourceIdentifier = 'NewProcess'
}

Register-CimIndicationEvent @paramHash
Get-EventSubscriber
notepad

$e = Get-Event

#details
#time is also part of the event object
$e.TimeGenerated
$e.SourceEventArgs
$e.SourceEventArgs.NewEvent
$e.SourceEventArgs.NewEvent.TargetInstance
$e.SourceEventArgs.NewEvent.TargetInstance.GetType()
$e.SourceEventArgs.NewEvent.TargetInstance.CreationDate

foreach ($event in (Get-Event)) {
    $target = $event.SourceEventArgs.NewEvent.TargetInstance
    [PSCustomObject]@{
        Date         = $event.TimeGenerated
        ProcessID    = $target.ProcessID
        ProcessName  = $target.Name
        Path         = $target.Path
        Computername = $target.CSName
    }
}

Get-Event | Remove-Event

#the max trigger of 1 automatically unregistered the event subscriber

# Unregister-Event NewProcess

#be selective
$query = "Select * from __InstanceCreationEvent within 5 Where TargetInstance ISA 'win32_process' AND TargetInstance.Name = 'pwsh.exe'"

$paramHash = @{
    Query            = $query
    ComputerName     = $Computername
    MessageData      = 'A new PowerShell process was detected'
    SourceIdentifier = 'New-PowerShell-Process'
}

Register-CimIndicationEvent @paramHash
Get-EventSubscriber

#start a new PowerShell session

Get-Event

foreach ($event in (Get-Event)) {
    $global:t = $target = $event.SourceEventArgs.NewEvent.TargetInstance
    #only works if process is still running
    try {
        $owner = Invoke-CimMethod -MethodName GetOwner -Query "Select * from Win32_Process where ProcessID=$($target.ProcessID)" -ComputerName $target.CSName -ErrorAction Stop
        if ($Owner.ReturnValue -eq 0) {
            $User = '{0}\{1}' -f $owner.domain, $owner.User
        }
        else {
            $User = $Null
        }
    }
    catch {
        $User = $Null
        Write-Warning $_.Exception.Message
    }
    [PSCustomObject]@{
        Date         = $event.TimeGenerated
        ProcessID    = $target.ProcessID
        ProcessName  = $target.Name
        Path         = $target.Path
        User         = $User
        Computername = $target.CSName
    }
}

Get-EventSubscriber | Unregister-Event
Get-Event | Remove-Event

#modification

Stop-Service Bits
$query = "Select * from __InstanceModificationEvent within 5 where TargetInstance ISA 'Win32_Service' AND TargetInstance.Name='BITS' AND TargetInstance.State='Running'"

$paramHash = @{
    Query            = $query
    SourceIdentifier = 'BITSWatch'
    MessageData      = 'BITS has started'
    ComputerName     = $ComputerName
}

Register-CimIndicationEvent @paramHash
Get-EventSubscriber

#staet the service and get the event
Get-Service bits | Start-Service -PassThru

$e = Get-Event -SourceIdentifier BitWatch | select -First 1

$e.SourceEventArgs.NewEvent
diff $e.SourceEventArgs.NewEvent.PreviousInstance $e.SourceEventArgs.NewEvent.TargetInstance -Property State

#use an action
$query = "Select * from __InstanceModificationEvent within 10 where TargetInstance ISA 'Win32_Service' AND TargetInstance.Name='BITS'"

$action = {
    #can use built-in variables
    # $event = the event object
    # $EventArgs = event.SourceEventArgs

    #case-sensitive
    $i = Get-Date -f 'yyyy-MM-dd_hhmmss_ff'
    $r = [PSCustomObject]@{
        Date         = $event.TimeGenerated
        Previous     = $EventArgs.NewEvent.PreviousInstance | select State, StartMode, PathName, StartName
        Target       = $EventArgs.NewEvent.TargetInstance | select State, StartMode, PathName, StartName
        Computername = $EventArgs.NewEvent.PreviousInstance.SystemName
    }
    $r | ConvertTo-Json | Out-File "c:\temp\bits-$i.json"
}

Register-CimIndicationEvent -Query $query -SourceIdentifier 'BITSMonitor2' -Action $action -ComputerName $ComputerName
#Action created as job

#test
Get-Event -SourceIdentifier BITSMonitor2

#change BITS state
(Get-Service bits).state -eq 'Running' ? (Stop-Service Bits -PassThru) : (Start-Service bits -PassThru)

#there is no event
Get-Event | group sourceIdentifier

Get-Job BITSMonitor2
dir c:\temp\bits-2026* | select -Last 1 | Get-Content
dir c:\temp\bits-2026*.json
dir c:\temp\bits-2026*.json | Get-Content | ConvertFrom-Json | Format-List

#clean up
Get-EventSubscriber | Unregister-Event
Get-Event | Remove-Event
Get-Job BITSMonitor2 | Remove-Job
dir c:\temp\bits-*.json | del
#endregion

#region process watcher

Get-CimClass win32_process*trace

#note change in query - not an Instance
$query = "Select * from Win32_ProcessStartTrace WITHIN 10 Where ProcessName = 'pwsh.exe'"
Register-CimIndicationEvent -Query $query -SourceIdentifier ProcessTrace -MessageData 'A new pwsh session has started'

#pwsh -noprofile

Get-Event -SourceIdentifier ProcessTrace | tee -Variable e
#more limited object
$e.SourceEventArgs.NewEvent

#get sid
$sid = New-Object System.Security.Principal.SecurityIdentifier($e.SourceEventArgs.NewEvent.Sid, 0)
$sid.Translate([System.Security.Principal.NTAccount]).value

#endregion

#region FileSystem watcher
New-Object System.IO.FileSystemWatcher

$fsw = [System.IO.FileSystemWatcher]::new('C:\temp')
$fsw
$fsw | Get-Member -MemberType Event | select Name
$fsw.EnableRaisingEvents = $True
$fsw.IncludeSubdirectories = $True
$splat = @{
    InputObject      = $fsw
    SourceIdentifier = 'tempWatch'
    MessageData      = 'A file has changed in C:\temp'
    EventName        = 'Changed'
}
Register-ObjectEvent @splat

#you might see double events
Get-Event

#limited information
(Get-Event)[0].SourceEventArgs

Get-Event | select EventIdentifier,TimeGenerated, @{Name = 'Path'; Expression = { $_.SourceEventArgs.FullPath } }

#Filter
$fsw.Filter = '*.ps1'
1..1000 | Out-File c:\temp\n.txt -append
code c:\temp\welcome.ps1
Get-Event | select TimeGenerated, @{Name = 'Path'; Expression = { $_.SourceEventArgs.FullPath } }

#code for handling multiple related events
$list = [System.Collections.Generic.List[object]]::new()
Get-Event -SourceIdentifier tempWatch | ForEach-Object { $list.Add($_) }
$offSetMS = 500
for ($i = 0 ; $i -lt $list.count; $i++) {
    $test = New-TimeSpan -Start $list[$i].TimeGenerated -End $list[$i + 1].TimeGenerated
    if ($test.TotalMilliseconds -ge $offSetMS) {
        Write-Host "Removing eventID $($list[$i].EventIdentifier)"
        $list.RemoveAt($i)
    }
}
$list | select EventIdentifier, TimeGenerated, @{Name = 'Path'; Expression = { $_.SourceEventArgs.FullPath } }

#Watch for VS Code closing
# Monitor VS Code workspace lock file
# this must be run outside of VSCode
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "$env:APPDATA\code"
$watcher.Filter = '*.lock'
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

#when is the lock file created
Register-ObjectEvent -InputObject $watcher -EventName 'Created' -SourceIdentifier VSCodeStart -Action {
    $ID = Get-Content "$env:APPDATA\code\code.lock"
    Get-Process -Id $id | select ID, Name, StartTime |
    ConvertTo-Json -Depth 1 | Out-File $env:temp\tmpCode.json
}
#when is the lock file removed
Register-ObjectEvent -InputObject $watcher -EventName 'Deleted' -SourceIdentifier VSCodeExit -Action {
    # Your cleanup code here
    $parent = Get-Content $env:temp\tmpCode.json | ConvertFrom-Json
    # Write-Host "VS Code workspace lock file deleted - VS Code ID $($parent.ID) is closing." -foreground Yellow
    $run = New-TimeSpan -Start $parent.StartTime -End (Get-Date)
    "[$(Get-Date)] VSCode process id $($parent.ID) runtime $run" | Out-File -FilePath c:\logs\vscode.txt -Encoding utf8 -Append
    Remove-Item -Path $env:temp\tmpCode.json
}

#endregion

#region PowerShell.Exit

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    # Get the history
    $history = Get-History

    # Convert the history to JSON
    $json = $history | Select-Object *,
    @{Name = 'Computername'; Expression = { [environment]::MachineName } } |
    ConvertTo-Json -Depth 1

    # Save the JSON to a file
    $file = 'C:\temp\History_{0:yyyyMMddhhmm}.json' -f (Get-Date)
    $json | Out-File -FilePath $file -Encoding utf8
} | Out-Null

Get-EventSubscriber PowerShell.Exiting

#endregion

#region PowerShell.OnIdle

https://github.com/jdhitsolutions/PSClock/blob/main/functions/ConsoleClock.ps1#L68-L114

#endregion

#region on module close

#register an event to remove the background session runspace
#when the module is removed
$OnRemoveScript = {
    #only run this code if the variable is defined
    if ($script:PSCmd) {
        $script:PSCmd.Runspace.Close()
        $script:PSCmd.Runspace.Dispose()
    }
    #clean up type data to avoid errors on re-importing
    'PSBlueskySession', 'PSBlueskySearchResult',
    'PSBlueskyProfile', 'PSBlueskyFollowProfile',
    'PSBlueskyFeedItem', 'PSBlueskyTimelinePost' | Remove-TypeData
    #clean up variables
    Get-Variable -Name bsky*, PDSHost, BSkySession -Exclude BskyPostCache |
    Remove-Variable -ErrorAction SilentlyContinue
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript

#endregion

#region startup monitor


#endregion
