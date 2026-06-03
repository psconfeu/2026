Start-Midi

Remove-Module PSMidi -Force -ErrorAction SilentlyContinue
Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi -Force
Clear-PSMidiQueue

#region Start midi connection
$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI.where({ $_.Name -eq 'NGGYU (A)' }).EndpointDeviceId
$session = Start-MidiSession 'NGGYU'
$connection = Open-MidiEndpointConnection $session $endpointDeviceId


#region DrumNotes
$drumTom1on  = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 0 -MessageStatus NoteOn
$drumTom1off = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 0 -MessageStatus NoteOff
$drumTom2on = New-PSMidiMessage -Note A -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumTom2off = New-PSMidiMessage -Note A -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumTom3on = New-PSMidiMessage -Note G -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumTom3off = New-PSMidiMessage -Note G -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumBasson = New-PSMidiMessage -Note C -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumBassoff = New-PSMidiMessage -Note C -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumSnareon = New-PSMidiMessage -Note D -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumSnareoff = New-PSMidiMessage -Note D -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumHHon = New-PSMidiMessage -Note 'F#' -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumHHoff = New-PSMidiMessage -Note 'F#' -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
$drumHHOpenon = New-PSMidiMessage -Note 'A#' -Octave 1 -MidiChannel 0 -MessageStatus NoteOn
$drumHHOpenoff = New-PSMidiMessage -Note 'A#' -Octave 1 -MidiChannel 0 -MessageStatus NoteOff
#endregion

#region BassNotes
## E - B - A
$BassEon  = New-PSMidiMessage -Note E -Octave 1 -MidiChannel 2 -MessageStatus NoteOn
$BassEoff = New-PSMidiMessage -Note E -Octave 1 -MidiChannel 2 -MessageStatus NoteOff

$BassBon  = New-PSMidiMessage -Note B -Octave 1 -MidiChannel 2 -MessageStatus NoteOn
$BassBoff = New-PSMidiMessage -Note B -Octave 1 -MidiChannel 2 -MessageStatus NoteOff

$BassAon  = New-PSMidiMessage -Note A -Octave 1 -MidiChannel 2 -MessageStatus NoteOn
$BassAoff = New-PSMidiMessage -Note A -Octave 1 -MidiChannel 2 -MessageStatus NoteOff

## F# - C# - B
$BassFSon  = New-PSMidiMessage -Note 'F#' -Octave 1 -MidiChannel 2 -MessageStatus NoteOn
$BassFSoff = New-PSMidiMessage -Note 'F#' -Octave 1 -MidiChannel 2 -MessageStatus NoteOff

$BassCSon  = New-PSMidiMessage -Note 'C#' -Octave 2 -MidiChannel 2 -MessageStatus NoteOn
$BassCSoff = New-PSMidiMessage -Note 'C#' -Octave 2 -MidiChannel 2 -MessageStatus NoteOff
## E - B - A
## G - F# - B

$BassGon  = New-PSMidiMessage -Note G -Octave 1 -MidiChannel 2 -MessageStatus NoteOn
$BassGoff = New-PSMidiMessage -Note G -Octave 1 -MidiChannel 2 -MessageStatus NoteOff

#endregion

#region ChordsNotes
## G
### G
$ChordGon = New-PSMidiMessage -Note G -Octave 3 -MidiChannel 4 -MessageStatus NoteOn
$ChordGoff = New-PSMidiMessage -Note G -Octave 3 -MidiChannel 4 -MessageStatus NoteOff
### B
$ChordBon = New-PSMidiMessage -Note B -Octave 3 -MidiChannel 4 -MessageStatus NoteOn
$ChordBoff = New-PSMidiMessage -Note B -Octave 3 -MidiChannel 4 -MessageStatus NoteOff
### D
$ChordDon = New-PSMidiMessage -Note D -Octave 4 -MidiChannel 4 -MessageStatus NoteOn
$ChordDoff = New-PSMidiMessage -Note D -Octave 4 -MidiChannel 4 -MessageStatus NoteOff

## A
### A
$ChordAon = New-PSMidiMessage -Note A -Octave 3 -MidiChannel 4 -MessageStatus NoteOn
$ChordAoff = New-PSMidiMessage -Note A -Octave 3 -MidiChannel 4 -MessageStatus NoteOff
### C#
$ChordCSon = New-PSMidiMessage -Note 'C#' -Octave 4 -MidiChannel 4 -MessageStatus NoteOn
$ChordCSoff = New-PSMidiMessage -Note 'C#' -Octave 4 -MidiChannel 4 -MessageStatus NoteOff
### E
$ChordEon = New-PSMidiMessage -Note E -Octave 4 -MidiChannel 4 -MessageStatus NoteOn
$ChordEoff = New-PSMidiMessage -Note E -Octave 4 -MidiChannel 4 -MessageStatus NoteOff

## F#m
### F#
$ChordFSon = New-PSMidiMessage -Note 'F#' -Octave 4 -MidiChannel 4 -MessageStatus NoteOn
$ChordFSoff = New-PSMidiMessage -Note 'F#' -Octave 4 -MidiChannel 4 -MessageStatus NoteOff
### A
### C#

## Bm
### B
### D
### F#

#endregion

#region SoloNotes
<#
b b d b F# F# e
a a c# a e e d
b b d b d e c# b a
a e d

b b d b F# F# e
a a c# a a(oct) c# d c# b
b b d b d e c# b a
a e d
#>

#endregion

#region stringFillNotes
<#
a b d e f# g 

d - e - a
e - f# - a g f#
d - e - a
a - b
#>

$StringFillAon  = New-PSMidiMessage -Note A -Octave 4 -MidiChannel 1 -MessageStatus NoteOn
$StringFillAoff = New-PSMidiMessage -Note A -Octave 4 -MidiChannel 1 -MessageStatus NoteOff

$StringFillAOcton  = New-PSMidiMessage -Note A -Octave 5 -MidiChannel 1 -MessageStatus NoteOn
$StringFillAOctoff = New-PSMidiMessage -Note A -Octave 5 -MidiChannel 1 -MessageStatus NoteOff

$StringFillBon  = New-PSMidiMessage -Note B -Octave 4 -MidiChannel 1 -MessageStatus NoteOn
$StringFillBoff = New-PSMidiMessage -Note B -Octave 4 -MidiChannel 1 -MessageStatus NoteOff

$StringFillDon  = New-PSMidiMessage -Note D -Octave 5 -MidiChannel 1 -MessageStatus NoteOn
$StringFillDoff = New-PSMidiMessage -Note D -Octave 5 -MidiChannel 1 -MessageStatus NoteOff

$StringFillEon  = New-PSMidiMessage -Note E -Octave 5 -MidiChannel 1 -MessageStatus NoteOn
$StringFillEoff = New-PSMidiMessage -Note E -Octave 5 -MidiChannel 1 -MessageStatus NoteOff

$StringFillFSon  = New-PSMidiMessage -Note 'F#' -Octave 5 -MidiChannel 1 -MessageStatus NoteOn
$StringFillFSoff = New-PSMidiMessage -Note 'F#' -Octave 5 -MidiChannel 1 -MessageStatus NoteOff

$StringFillGon  = New-PSMidiMessage -Note G -Octave 5 -MidiChannel 1 -MessageStatus NoteOn
$StringFillGoff = New-PSMidiMessage -Note G -Octave 5 -MidiChannel 1 -MessageStatus NoteOff
#endregion



# 226 bpm * 4
Start-PSMidiQueue -Tempo 904 -Beat 255 -Connection $connection


#region Main drumbeat
0..255 | % { 
    if ((($_ % 16) + 1) -eq 1) {
        Add-PSMidiQueueMessage -Message $drumHHon -Every ($_ + 1)
        Add-PSMidiQueueMessage -Message $drumBasson -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 5) {
        Add-PSMidiQueueMessage -Message $drumHHOpenon -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 9) {
        Add-PSMidiQueueMessage -Message $drumHHon -Every ($_ + 1)
        Add-PSMidiQueueMessage -Message $drumSnareon -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 13) {
        Add-PSMidiQueueMessage -Message $drumHHOpenon -Every ($_ + 1)
    }

    
    elseif ((($_ % 16) + 1) -eq 3) {
        Add-PSMidiQueueMessage -Message $drumHHoff -Every ($_ + 1)
        Add-PSMidiQueueMessage -Message $drumBassoff -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 7) {
        Add-PSMidiQueueMessage -Message $drumHHOpenoff -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 11) {
        Add-PSMidiQueueMessage -Message $drumHHoff -Every ($_ + 1)
        Add-PSMidiQueueMessage -Message $drumSnareoff -Every ($_ + 1)
    }
    elseif ((($_ % 16) + 1) -eq 15) {
        Add-PSMidiQueueMessage -Message $drumHHOpenoff -Every ($_ + 1)
    }
} 
#endregion

#region fill
$drumTom1on | % {
    Add-PSMidiQueueMessage -Message $_ -Every 241
    Add-PSMidiQueueMessage -Message $_ -Every 243
}

$drumTom1off, $drumTom2on | % {
    Add-PSMidiQueueMessage -Message $_ -Every 247
}

$drumTom2off, $drumTom2on | % {
    Add-PSMidiQueueMessage -Message $_ -Every 249
}

$drumTom2off, $drumTom2on | % {
    Add-PSMidiQueueMessage -Message $_ -Every 251
}

$drumTom2off, $drumTom3on | % {
    Add-PSMidiQueueMessage -Message $_ -Every 253
}

$drumTom3off | % {
    Add-PSMidiQueueMessage -Message $_ -Every 255
}
#endregion

#region Bass
## E - B - A
Add-PSMidiQueueMessage -Message $BassEon -Every 1
Add-PSMidiQueueMessage -Message $BassEoff -Every 7
Add-PSMidiQueueMessage -Message $BassEon -Every 129
Add-PSMidiQueueMessage -Message $BassEoff -Every 135

Add-PSMidiQueueMessage -Message $BassBon -Every 7
Add-PSMidiQueueMessage -Message $BassBoff -Every 13
Add-PSMidiQueueMessage -Message $BassBon -Every 135
Add-PSMidiQueueMessage -Message $BassBoff -Every 141

Add-PSMidiQueueMessage -Message $BassAon -Every 13
Add-PSMidiQueueMessage -Message $BassAoff -Every 33
Add-PSMidiQueueMessage -Message $BassAon -Every 141
Add-PSMidiQueueMessage -Message $BassAoff -Every 161

## F# - C# - B
Add-PSMidiQueueMessage -Message $BassFSon -Every 33
Add-PSMidiQueueMessage -Message $BassFSoff -Every 39
Add-PSMidiQueueMessage -Message $BassFSon -Every 161
Add-PSMidiQueueMessage -Message $BassFSoff -Every 167

Add-PSMidiQueueMessage -Message $BassCSon -Every 39
Add-PSMidiQueueMessage -Message $BassCSoff -Every 45
Add-PSMidiQueueMessage -Message $BassCSon -Every 167
Add-PSMidiQueueMessage -Message $BassCSoff -Every 173

Add-PSMidiQueueMessage -Message $BassBon -Every 45
Add-PSMidiQueueMessage -Message $BassBoff -Every 65
Add-PSMidiQueueMessage -Message $BassBon -Every 173
Add-PSMidiQueueMessage -Message $BassBoff -Every 193

## E - B - A
Add-PSMidiQueueMessage -Message $BassEon -Every 65
Add-PSMidiQueueMessage -Message $BassEoff -Every 71
Add-PSMidiQueueMessage -Message $BassEon -Every 193
Add-PSMidiQueueMessage -Message $BassEoff -Every 199

Add-PSMidiQueueMessage -Message $BassBon -Every 71
Add-PSMidiQueueMessage -Message $BassBoff -Every 77
Add-PSMidiQueueMessage -Message $BassBon -Every 199
Add-PSMidiQueueMessage -Message $BassBoff -Every 205

Add-PSMidiQueueMessage -Message $BassAon -Every 77
Add-PSMidiQueueMessage -Message $BassAoff -Every 89
Add-PSMidiQueueMessage -Message $BassAon -Every 205
Add-PSMidiQueueMessage -Message $BassAoff -Every 217

## G - F# - B
Add-PSMidiQueueMessage -Message $BassGon -Every 89
Add-PSMidiQueueMessage -Message $BassGoff -Every 97
Add-PSMidiQueueMessage -Message $BassGon -Every 217
Add-PSMidiQueueMessage -Message $BassGoff -Every 225

Add-PSMidiQueueMessage -Message $BassFSon -Every 97
Add-PSMidiQueueMessage -Message $BassFSoff -Every 105
Add-PSMidiQueueMessage -Message $BassFSon -Every 225
Add-PSMidiQueueMessage -Message $BassFSoff -Every 233

Add-PSMidiQueueMessage -Message $BassBon -Every 105
Add-PSMidiQueueMessage -Message $BassBoff -Every 129
Add-PSMidiQueueMessage -Message $BassBon -Every 233
Add-PSMidiQueueMessage -Message $BassBoff -Every 1
#endregion

#region main Chords
$ChordBoff, $ChordDoff, $ChordFSoff, $ChordGon, $ChordDon, $ChordBon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 1
    Add-PSMidiQueueMessage -Message $_ -Every 65
    Add-PSMidiQueueMessage -Message $_ -Every 129
    Add-PSMidiQueueMessage -Message $_ -Every 193
}

$ChordGoff, $ChordDoff, $ChordBoff, $ChordAon, $ChordCSon, $ChordEon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 13
    Add-PSMidiQueueMessage -Message $_ -Every 77
    Add-PSMidiQueueMessage -Message $_ -Every 141
    Add-PSMidiQueueMessage -Message $_ -Every 205
}

$ChordAoff, $ChordCSoff, $ChordEoff, $ChordFSon, $ChordAon, $ChordCSon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 33
    Add-PSMidiQueueMessage -Message $_ -Every 97
    Add-PSMidiQueueMessage -Message $_ -Every 161
    Add-PSMidiQueueMessage -Message $_ -Every 225
}

$ChordFSoff, $ChordAoff, $ChordCSoff, $ChordBon, $ChordDon, $ChordFSon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 45
    Add-PSMidiQueueMessage -Message $_ -Every 109
    Add-PSMidiQueueMessage -Message $_ -Every 173
    Add-PSMidiQueueMessage -Message $_ -Every 237
}

#endregion


#region stringFillNotes
# d - e - a
$StringFillBoff, $StringFillDon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 1
    Add-PSMidiQueueMessage -Message $_ -Every 129
}

$StringFillDoff, $StringFillEon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 13
    Add-PSMidiQueueMessage -Message $_ -Every 141
}

$StringFillEoff, $StringFillAon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 25
    Add-PSMidiQueueMessage -Message $_ -Every 153
}

# e - f# - a g f#
$StringFillAoff, $StringFillEon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 33
    Add-PSMidiQueueMessage -Message $_ -Every 161
}

$StringFillEoff, $StringFillFSon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 45
    Add-PSMidiQueueMessage -Message $_ -Every 173
}

$StringFillFSoff, $StringFillAOcton | % {
    Add-PSMidiQueueMessage -Message $_ -Every 57
    Add-PSMidiQueueMessage -Message $_ -Every 185
}

$StringFillAOctoff, $StringFillGon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 59
    Add-PSMidiQueueMessage -Message $_ -Every 187
}

$StringFillGoff, $StringFillFSon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 61
    Add-PSMidiQueueMessage -Message $_ -Every 189
}

# d - e - a
$StringFillFSoff, $StringFillDon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 65
    Add-PSMidiQueueMessage -Message $_ -Every 193
}

$StringFillDoff, $StringFillEon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 77
    Add-PSMidiQueueMessage -Message $_ -Every 205
}

$StringFillEoff, $StringFillAon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 89
    Add-PSMidiQueueMessage -Message $_ -Every 217
}

# a - b

$StringFillAoff, $StringFillAon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 93
    Add-PSMidiQueueMessage -Message $_ -Every 221
}

$StringFillAoff, $StringFillBon | % {
    Add-PSMidiQueueMessage -Message $_ -Every 105
    Add-PSMidiQueueMessage -Message $_ -Every 233
}
#endregion



Stop-PSMidiQueue
# Get-Variable -Name drum*On | % { $_.Name ; send-PSMidiMessage -Connection $connection -Message $_.Value ; start-sleep -Seconds 1}


Get-Variable -Name *Off | % { $_.Name ; send-PSMidiMessage -Connection $connection -Message $_.Value}



# send-PSMidiMessage -Connection $connection -Message $drumTom2on
# send-PSMidiMessage -Connection $connection -Message $drumTom1off 

