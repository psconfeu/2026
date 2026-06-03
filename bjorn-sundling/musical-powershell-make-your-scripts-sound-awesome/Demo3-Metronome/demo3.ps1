#region setup

Import-Module WindowsMidiServices
ipmo \GitHub\bjompen\PSMidi\Source\PSMidi
Start-Midi
$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI[1].EndpointDeviceId
Get-MidiEndpointDeviceInfo $endpointDeviceId
$session = Start-MidiSession "PSConf Demo Session"
$connection = Open-MidiEndpointConnection $session $endpointDeviceId


#endregion






# Creating a drum beat

#region clean up any old jobs..
Get-EventSubscriber | Unregister-Event
Get-Job | Stop-Job
Get-Job | Remove-Job
#endregion




## What the h*ll is a beat?

# in 60 BPM we need to do something every second. To slow - lets do 120 BPM...





#region while loop
$hhOn = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOn
$hhOff = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOff
$bassOn = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOn
$bassOff = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOff
$snareOn = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOn
$snareOff = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOff

$beat = 1

while ($true) {
    if ($beat -eq 1) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    }
    elseif ($beat -eq 2) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
    }
    elseif ($beat -eq 3) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOn.Word0, $snareOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOff.Word0, $snareOff.Word1)
    }
    elseif ($beat -eq 4) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
    }

    start-sleep -Milliseconds 500
    $beat++
    if ($beat -eq 5) {
        $beat = 1
    }
}

# Not metal enough!

$beat = 1

while ($true) {
    if ($beat -eq 1) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    }
    elseif ($beat -eq 2) {
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    }
    elseif ($beat -eq 3) {
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOn.Word0, $snareOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOff.Word0, $snareOff.Word1)
    }
    elseif ($beat -eq 4) {
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    }

    start-sleep -Milliseconds 100
    $beat++
    if ($beat -eq 5) {
        $beat = 1
    }
}


# Works! But locks my terminal. How can I play more without terminal?!

#endregion





# Powershell has timers! Awesome!

[System.Timers.Timer]::new
# Interval is in milliseconds. 1000 milliseconds is one second.

#region try it with output

$te = [System.Timers.Timer]::new(1000)

# We need to reset our timer every time to calculate 500 new ms..
$te.AutoReset = $true

# What should it do?
$testTimer = {
    param($a, $b)
    Write-Host "Time: $($b.SignalTime)"
}

Register-ObjectEvent -InputObject $te -EventName Elapsed -SourceIdentifier 'Timer' -Action $testTimer

$te.Start()

$te.Stop()

#endregion




#region beat it!
$te = [System.Timers.Timer]::new(1000)
$te.AutoReset = $true

# What should it do? -remember this is in its own scope! Everything needs to be here!
# WATCH OUT!! THIS WILL CRASH POWERSHELL! 
$testTimer = {

    Import-Module WindowsMidiServices
    ipmo \GitHub\bjompen\PSMidi\Source\PSMidi
    Start-Midi
    $EDI = Get-MidiEndpointDeviceInfoList
    $endpointDeviceId = $EDI[1].EndpointDeviceId
    Get-MidiEndpointDeviceInfo $endpointDeviceId
    $session = Start-MidiSession "PSConf Demo Session"
    $connection = Open-MidiEndpointConnection $session $endpointDeviceId

    $hhOn = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOn
    $hhOff = New-PSMidiMessage -Note D -Octave 3 -MessageStatus NoteOff
    $bassOn = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOn
    $bassOff = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOff
    $snareOn = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOn
    $snareOff = New-PSMidiMessage -Note D -Octave 1 -MessageStatus NoteOff

    [int]$beat++
    
    if ($beat -eq 1) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    }
    elseif ($beat -eq 2) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
    }
    elseif ($beat -eq 3) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOn.Word0, $snareOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
        Send-MidiMessage -Connection $connection -Words $($snareOff.Word0, $snareOff.Word1)
    }
    elseif ($beat -eq 4) {
        Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
        Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
    }

    if ($CurrentBeat -eq 4) {
        $CurrentBeat = 0
    }
}

# clean up any old jobs..
Get-EventSubscriber | Unregister-Event
Get-Job | Stop-Job
Get-Job | Remove-Job

Register-ObjectEvent -InputObject $te -EventName Elapsed -SourceIdentifier 'Timer' -Action $testTimer

$te.Start()

$te.Stop()

#endregion







#region a _working_ metronome
code '\GitHub\bjompen\PSMidi\Source\Public\Start-Metronome.ps1'

Start-Metronome -Tempo 120 -ScriptBlock {} -Verbose

# break w. Ctrl+c

# Technically works - but PowerShell is still in it's own scope which causes all kinds of weirdness...
Import-Module WindowsMidiServices
ipmo \GitHub\bjompen\PSMidi\Source\PSMidi
Start-Midi

Start-Metronome -Tempo 120 -ScriptBlock {
    Import-Module WindowsMidiServices
    ipmo \GitHub\bjompen\PSMidi\Source\PSMidi
    Start-Midi
    $EDI = Get-MidiEndpointDeviceInfoList
    $endpointDeviceId = $EDI[1].EndpointDeviceId
    $session = Start-MidiSession "PSConf Demo Session"
    $connection = Open-MidiEndpointConnection $session $endpointDeviceId

    $bassOn = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOn
    $bassOff = New-PSMidiMessage -Note C -Octave 1 -MessageStatus NoteOff

    Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
    Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
    Close-MidiEndpointConnection -Session $session -Connection $connection

} -Verbose

#endregion




#region The solution - Threadjobs

Start-ThreadJob -Name 'Demo3ThreadJob' -ScriptBlock {
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

    $beat = 1

    while ($true) {
        if ($beat -eq 1) {
            Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
            Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
        }
        elseif ($beat -eq 2) {
            Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
        }
        elseif ($beat -eq 3) {
            Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($hhOn.Word0, $hhOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($snareOn.Word0, $snareOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
            Send-MidiMessage -Connection $connection -Words $($hhOff.Word0, $hhOff.Word1)
            Send-MidiMessage -Connection $connection -Words $($snareOff.Word0, $snareOff.Word1)
        }
        elseif ($beat -eq 4) {
            Send-MidiMessage -Connection $connection -Words $($bassOn.Word0, $bassOn.Word1)
            Send-MidiMessage -Connection $connection -Words $($bassOff.Word0, $bassOff.Word1)
        }

        start-sleep -Milliseconds 200
        $beat++
        if ($beat -eq 5) {
            $beat = 1
        }
    }
}


Get-EventSubscriber | Unregister-Event
get-Job | stop-Job
get-Job | remove-Job

#endregion
