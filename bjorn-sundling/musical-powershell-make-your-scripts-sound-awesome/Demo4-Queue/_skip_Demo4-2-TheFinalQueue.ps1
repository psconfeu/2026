# So I settled for a generic dict as queue. 
# beat number as index ("Should I play this now")
# Note array as value ("What should be played on this beat")

#region simple demo

$playQueue = [System.Collections.Generic.Dictionary[int, string[]]]::new()

$playQueue.Add(1, 'note 1')
$playQueue.Add(3, 'note 3')

Start-ThreadJob -Name 'queuejob' -ScriptBlock {
    $q = $Using:playQueue
    $c = 1

    while ($true) {
        Write-Output "Current notes: >>$($q[$c] -join ', ')<<"
        Start-Sleep -Seconds 1
        $c++
        if ($c -eq 5) { $c = 1}
    }
}

Get-Job -Name 'queuejob' | Receive-Job

$playQueue.Add(2, 'note 2')

Get-Job -Name 'queuejob' | Receive-Job


if ($playQueue.ContainsKey(4)) {
    $playQueue[4] += 'note 4++'
}
else {
    $playQueue.Add(4, 'note 4')
}

Get-Job -Name 'queuejob' | Receive-Job



Get-Job -Name 'queuejob' | Stop-Job
Get-Job -Name 'queuejob' | Remove-Job

#endregion

#region Real demo

Remove-Module PSMidi -Force -ErrorAction SilentlyContinue
Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi -Force
Start-Midi
Clear-PSMidiQueue

#region Start midi connection
$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI[-1]
$session = Start-MidiSession 'dbeat'
$connection = Open-MidiEndpointConnection $session $endpointDeviceId

$drumBasson = New-PSMidiMessage -Note C -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumBassoff = New-PSMidiMessage -Note C -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumSnareon = New-PSMidiMessage -Note E -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumSnareoff = New-PSMidiMessage -Note E -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumHHon = New-PSMidiMessage -Note D -Octave 3 -MidiChannel 0 -MessageStatus NoteOn
$drumHHoff = New-PSMidiMessage -Note D -Octave 3 -MidiChannel 0 -MessageStatus NoteOff

Start-PSMidiQueue -Tempo 120 -Beat 16 -Connection $connection


$drumHHon, $drumHHoff | % {
    foreach ($n in @(1,3,5,7,9,11,13,15)) {
        Add-PSMidiQueueMessage -Message $_ -Every $n
    }
}



foreach ($n in @(5, 13)) {
    Add-PSMidiQueueMessage -Message $drumSnareon -Every $n
}
foreach ($n in @(6, 14)) {
    Add-PSMidiQueueMessage -Message $drumSnareoff -Every $n
}



foreach ($n in @(1, 9)) {
    Add-PSMidiQueueMessage -Message $drumBasson -Every $n
}
foreach ($n in @(2, 10)) {
    Add-PSMidiQueueMessage -Message $drumBassoff -Every $n
}


Stop-PSMidiQueue
Clear-PSMidiQueue

Send-PSMidiMessage -Connection $connection -Message $drumHHoff
Send-PSMidiMessage -Connection $connection -Message $drumSnareoff
Send-PSMidiMessage -Connection $connection -Message $drumBassoff
