Get-Job | Stop-Job
Get-Job | Remove-Job


# Next problem: How do I add beats or notes to a job?
# Sharing variables between scopes doesn't work. The metronome uses jobs. How do I queue?

#region Doesnt work
$me_the_rockstar = 'Björn'
Start-ThreadJob -Name 'Doesnt Work' -ScriptBlock {
    Write-Output "Hello >>$me_the_rockstar<<"
}

Get-Job -Name 'Doesnt work' | Receive-Job

Get-Job -Name 'Doesnt work' | Remove-Job
#endregion


#region Using almost works
$me_the_rockstar = 'Björn'
Start-ThreadJob -Name 'almost works' -ScriptBlock {
    Write-Output "Hello $using:me_the_rockstar"
}

Get-Job -Name 'almost works' | Receive-Job

Get-Job -Name 'almost works' | Remove-Job

# almost....
Start-ThreadJob -Name 'almost works' -ScriptBlock {
    While ($true) {
        Write-Output "Hello $using:me_the_rockstar"
        Start-Sleep -Seconds 1
    }
}


$me_the_rockstar = '666undling'

Get-Job -Name 'almost works' | Receive-Job


Get-Job -Name 'almost works' | Stop-Job
Get-Job -Name 'almost works' | Remove-Job
#endregion



# Enter the thread safe universe

#region For shared _writes_ look at System.Collections.Concurrent
$concurrentDemo = [System.Collections.Concurrent.ConcurrentDictionary[int, string]]::new()

$concurrentDemo[1] = 'Björn'

Start-ThreadJob -Name 'ConcurrectDict' -ScriptBlock {
    While ($true) {
        $ccd = $using:concurrentDemo
        $ccd[$(Get-Random -Minimum 1000000 -Maximum 9999999)] = 'Björn'
        Start-Sleep -Seconds 1
    }
}

$concurrentDemo[2] = 'Björn'

$concurrentDemo[3] = 'Björn'

Get-Job -Name 'ConcurrectDict' | Stop-Job

$concurrentDemo

Get-Job -Name 'ConcurrectDict' | Remove-Job

#endregion

#region System.Collections and System.Collections.Generic works for _read_. Good enough.
& 'firefox.exe' 'https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic?view=net-10.0'

# but which one?
#endregion





#region Testing a queue - In case of time :)
$q = [System.Collections.Generic.Queue[string]]::new()
$q.Enqueue('Björn')
$q.Enqueue('Likes')
$q.Enqueue('Metal')

$q.Peek()

$q.Dequeue()
# nope - I dont always want the "oldest" note played
#endregion



#region testing a linked list - In case of time :)

[string[]]$rockstarSentence = @('Björn', 'Trve', 'Metal')

$ll = [System.Collections.Generic.LinkedList[string]]::new($rockstarSentence)

$ll

$null = $ll.AddFirst('WorldFamousSuperstar')

$ll

$llNode = $ll.Find('Trve') 
$null = $ll.AddBefore($llNode, 'Is')

$ll

# Cool, but not at all what I need...
#endregion




#region testing a sorted queue - In case of time :)
$sl = [System.Collections.Generic.SortedList[int, string]]::new()

$sl.Add(2, 'play note 2')
$sl.Add(3, 'play note 3')
$sl.Add(4, 'play note 4')

$sl

$sl.Add(1, 'play note 1')

$sl
# May actually work.. But injecting notes earlier than "now" seems useless
#endregion





#region In the end... A standard generic dictionary turns out to be enough..
Import-Module WindowsMidiServices
ipmo \GitHub\bjompen\PSMidi\Source\PSMidi
Start-Midi
$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI[1].EndpointDeviceId
$session = Start-MidiSession "PSConf Demo Session"
$connection = Open-MidiEndpointConnection $session $endpointDeviceId

$hhOn = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOn
$hhOff = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOff
$bassOn = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOn
$bassOff = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOff
$snareOn = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOn
$snareOff = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOff
################



$gd = [System.Collections.Generic.Dictionary[int, Microsoft.Windows.Devices.Midi2.MidiMessage64[]]]::New()
$gd.Add(1, @($bassOn, $hhOn))
$gd.Add(2, @($bassOff, $hhOff))


Start-ThreadJob -Name 'almost works' -ScriptBlock {
    $gdLocal = $using:gd
    $gdConn = $using:connection

    $beat = 1

    while ($true) {
        $gdLocal[$beat] | Sort-Object -Property Word0 | ForEach-Object {
            Send-MidiMessage -Connection $gdConn -Words @($_.Word0, $_.Word1)
        }
        
        start-sleep -Milliseconds 100
        $beat++
        if ($beat -eq 9) {
            $beat = 1
        }
    }
}


$gd.Add(3, @($bassOn, $hhOn))
$gd.Add(4, @($bassOff, $hhOff))
$gd.Add(5, @($bassOn, $hhOn, $snareOn))
$gd.Add(6, @($bassOff, $hhOff, $snareOff))
$gd.Add(7, @($bassOn, $hhOn))
$gd.Add(8, @($bassOff, $hhOff))


Get-EventSubscriber | Unregister-Event
get-Job | stop-Job
get-Job | remove-Job



$gd

#endregion
