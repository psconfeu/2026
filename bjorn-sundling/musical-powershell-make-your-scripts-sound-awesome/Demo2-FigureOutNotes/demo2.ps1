# & "C:\Program Files\REAPER (arm64)\reaper.exe" '\MusicalPowerShell\Demo2\demo2.rpp'

# Safetybreak!
break


#region reading the docs
& 'firefox.exe' '\PSConf\MusicalPowerShell\Demo2-FigureOutNotes\M2-104-UM_v1-1-2_UMP_and_MIDI_2-0_Protocol_Specification.pdf'
# Page 49
# 7.4 – MIDI 2.0 channel voice message


# Sending a message - the SDK example
$messages = (0x40905252, 0x02001111)

<#
(0x40905252, 0x02001111) 
0x
    4 = Midi channel voice message
    0 = group
    9 = note on - 8 = note off
    0 = Midi channel
    5252 = index
        52 = note number (C, D, E etc)
        52 = Attribute type

0x
    0200 = MIDI 2.0 velocity, range 0x0000 to 0xFFFF
    1111 = ???Attribute data????
#>

#endregion



#Region 32 bit packages math

# What does the package look like in binary?
[convert]::ToString('0x40905252', 2)

# What does the package look like in binary - but somewhat more easy readable?
([convert]::ToString('0x40905252', 2)).PadLeft(32,'0') -split '(.{8})' -ne '' |  % {$_ -replace '^(.{4})','$1 '}


<#
0100 0000
1001 <- This byte is NoteOn. NoteOf is 1000 as per midi spec, page 50, 7.4.1 and 7.4.2
#>


# So the 8 bits of '52' - what do they look like as an int?
[Convert]::ToInt32(01010010, 2)

& 'firefox.exe' 'https://inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies'

# ...And back to hex
'{0:x2}' -f 82

#endregion










#region Counting notes
$Note = 'C'
$Octave = 4
$Group = 0
$MidiChannel = 0

$chordsList = 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'

# -shl - shift left
# 8 = 1000
# 8 -shl 2 = 100000

# 32 bit
$mt = 0x4 -shl 28 # Midi channel voice message
$group = $Group -shl 24
$midiNoteOn = 9 -shl 20
$midiNoteOff = 8 -shl 20
$midiChannel = $MidiChannel -shl 16


[int]$octaveRange = ($Octave + 1) * 12
$playNote = ($octaveRange + $chordsList.IndexOf($Note.ToUpper())) -shl 8

$attribute = 82

$onMessage = $mt -bor $group -bor $midiNoteOn -bor $MidiChannel -bor $playNote -bor $attribute
$offMessage = $mt -bor $group -bor $midiNoteOff -bor $MidiChannel -bor $playNote -bor $attribute

$o = "{0:x2}" -f $onMessage
Write-Host $o

# Dont do this until you prepared the NoteOff...
Read-Host # If i forget - this pauses the code ;)

Send-MidiMessage $connection ($onMessage, 0x02000000) -Timestamp 0


[UInt]$Length = 1000
Start-Sleep -Milliseconds $Length

$o = "{0:x2}" -f $offMessage
Write-Host $o

Send-MidiMessage $connection ($offMessage, 0x02000000) -Timestamp 0

#endregion






# there are two things I need to improve here:
# Calculating chords, and creating midi message data


#region a better way to calculate chords

enum NoteIndex {
    C = 0
    D = 2
    E = 4
    F = 5
    G = 7
    A = 9
    B = 11
    H = 11
}
Class Chord {
    [string] $BaseChord
    [int] $Octave
    [string] $Alt
    hidden [int] $AltMidi
    [int] $MidiNote

    Chord($Chord) {
        $null = $Chord -match '^(?<BaseNote>[a-gA-G])(?<Alt>[#b]?)(?<Octave>(-?[1-2]|[0-8])$)'

        $this.BaseChord = $Matches['BaseNote'].ToUpper()
        $this.Alt = $Matches['Alt'] ?? [string]::Empty
        $this.AltMidi = $Matches['Alt'] -eq 'b' ? [int]-1 : $Matches['Alt'] -eq '#' ? 1 : 0
        $this.Octave = $Matches['Octave']
        $this.MidiNote = (
            ([NoteIndex]$Matches['BaseNote'].ToUpper()).value__ + $this.AltMidi
        ) + (
            ([int]$Matches['Octave'] + 2) * 12)
    }
}


[chord]::new('C3')

[chord]::new('C#3')

[chord]::new('Db3')

#endregion




#region Midi2 classes can create notes. Less maths, more good

$Group = 0
$MessageStatus = 9
$MidiChannel = 0
$playNote = 15360


[Microsoft.Windows.Devices.Midi2.Messages.MidiMessageBuilder]::BuildMidi2ChannelVoiceMessage(
    0,
    [Microsoft.Windows.Devices.Midi2.MidiGroup]::new($Group),
    $MessageStatus, # This is noteOn or noteOf
    [Microsoft.Windows.Devices.Midi2.MidiChannel]::new($MidiChannel),
    $playNote, # Midi index note - i.e C3 = 60
    $messageData # "The second package"
)


Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi
new-psmidiMessage -Note C -Octave 3

# Word0 and Word1. But wait - those are not hex?! Turns out that doesnt matter...
$noteOn = New-PSMidiMessage -Note C -Octave 3 -MessageStatus NoteOn
$noteOff = New-PSMidiMessage -Note C -Octave 3 -MessageStatus NoteOff

Send-MidiMessage -Connection $connection -Words $($noteOn.Word0, $noteOn.Word1)

Send-MidiMessage -Connection $connection -Words $($noteOff.Word0, $noteOff.Word1)

# Chords are of! C3 in PSMidi is C4 in Reaper. Chord calculations are weird...
#endregion

