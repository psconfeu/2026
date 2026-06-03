Start-Midi

Remove-Module PSMidi -Force -ErrorAction SilentlyContinue
Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi -Force
Clear-PSMidiQueue

#region Start midi connection
$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI.where({ $_.Name -eq 'NGGYU (A)' }).EndpointDeviceId
$session = Start-MidiSession 'NGGYU'
$connection = Open-MidiEndpointConnection $session $endpointDeviceId





Start-PSMidiQueue -Tempo 240 -Beat 63 -Connection $connection -Verbose







#region seqNotes
$seq1on = New-PSMidiMessage -Note C -Octave 4 -MidiChannel 0 -MessageStatus NoteOn
$seq1off = New-PSMidiMessage -Note C -Octave 4 -MidiChannel 0 -MessageStatus NoteOff


Add-PSMidiQueueMessage -Message $seq1on -Every 0
Add-PSMidiQueueMessage -Message $seq1off -Every 0
# send-PSMidiMessage -Connection $connection -Message $seq1on
# send-PSMidiMessage -Connection $connection -Message $seq1off 
#endregion





#region bassNotes
$bassCon = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 1 -MessageStatus NoteOn
$bassCoff = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 1 -MessageStatus NoteOff
$bassFon = New-PSMidiMessage -Note F -Octave 2 -MidiChannel 1 -MessageStatus NoteOn
$bassFoff = New-PSMidiMessage -Note F -Octave 2 -MidiChannel 1 -MessageStatus NoteOff
$bassAon = New-PSMidiMessage -Note A -Octave 2 -MidiChannel 1 -MessageStatus NoteOn
$bassAoff = New-PSMidiMessage -Note A -Octave 2 -MidiChannel 1 -MessageStatus NoteOff
$bassDon = New-PSMidiMessage -Note D -Octave 2 -MidiChannel 1 -MessageStatus NoteOn
$bassDoff = New-PSMidiMessage -Note D -Octave 2 -MidiChannel 1 -MessageStatus NoteOff


Add-PSMidiQueueMessage -Message $bassCon -Every 0
Add-PSMidiQueueMessage -Message $bassFon -Every 16
Add-PSMidiQueueMessage -Message $bassAon -Every 32
Add-PSMidiQueueMessage -Message $bassDon -Every 48

Add-PSMidiQueueMessage -Message $bassDoff -Every 0
Add-PSMidiQueueMessage -Message $bassCoff -Every 16
Add-PSMidiQueueMessage -Message $bassFoff -Every 32
Add-PSMidiQueueMessage -Message $bassAoff -Every 48
#endregion




#region drumNotes
$kickon = New-PSMidiMessage -Note C -Octave 0 -MidiChannel 2 -MessageStatus NoteOn
$kickoff = New-PSMidiMessage -Note C -Octave 0 -MidiChannel 2 -MessageStatus NoteOff

$hhCloseon = New-PSMidiMessage -Note 'G#' -Octave 1 -MidiChannel 5 -MessageStatus NoteOn
$hhCloseoff = New-PSMidiMessage -Note 'G#' -Octave 1 -MidiChannel 5 -MessageStatus NoteOff

$hhOpenon = New-PSMidiMessage -Note 'A#' -Octave 1 -MidiChannel 5 -MessageStatus NoteOn
$hhOpenoff = New-PSMidiMessage -Note 'A#' -Octave 1 -MidiChannel 5 -MessageStatus NoteOff


0..63 | % {
    if (($_ % 2) -eq 0) {
        Add-PSMidiQueueMessage -Message $kickon -Every $_
        Add-PSMidiQueueMessage -Message $hhCloseon -Every $_
        Add-PSMidiQueueMessage -Message $hhOpenoff -Every $_
    }
    else {
        Add-PSMidiQueueMessage -Message $kickoff -Every $_
        Add-PSMidiQueueMessage -Message $hhCloseoff -Every $_
        Add-PSMidiQueueMessage -Message $hhOpenon -Every $_
    }
}
#endregion




#region chordNotes
$chordCon = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordCoff = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOff
$chordEon = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordEoff = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOff
$chordGon = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordGoff = New-PSMidiMessage -Note C -Octave 2 -MidiChannel 4 -MessageStatus NoteOff



$chordFon = New-PSMidiMessage -Note F -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordFoff = New-PSMidiMessage -Note F -Octave 2 -MidiChannel 4 -MessageStatus NoteOff
$chordAon = New-PSMidiMessage -Note A -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordAoff = New-PSMidiMessage -Note A -Octave 2 -MidiChannel 4 -MessageStatus NoteOff


$chordC2on = New-PSMidiMessage -Note C -Octave 3 -MidiChannel 4 -MessageStatus NoteOn
$chordC2off = New-PSMidiMessage -Note C -Octave 3 -MidiChannel 4 -MessageStatus NoteOff

$chordDon = New-PSMidiMessage -Note D -Octave 2 -MidiChannel 4 -MessageStatus NoteOn
$chordDoff = New-PSMidiMessage -Note D -Octave 2 -MidiChannel 4 -MessageStatus NoteOff


Add-PSMidiQueueMessage -Message $chordCon -Every 0
Add-PSMidiQueueMessage -Message $chordEon -Every 0
Add-PSMidiQueueMessage -Message $chordGon -Every 0

Add-PSMidiQueueMessage -Message $chordFon -Every 16
Add-PSMidiQueueMessage -Message $chordGon -Every 16
Add-PSMidiQueueMessage -Message $chordCon -Every 16

Add-PSMidiQueueMessage -Message $chordEon -Every 32
Add-PSMidiQueueMessage -Message $chordAon -Every 32
Add-PSMidiQueueMessage -Message $chordC2on -Every 32

Add-PSMidiQueueMessage -Message $chordDon -Every 48
Add-PSMidiQueueMessage -Message $chordFon -Every 48
Add-PSMidiQueueMessage -Message $chordAon -Every 48


Add-PSMidiQueueMessage -Message $chordDoff -Every 0
Add-PSMidiQueueMessage -Message $chordFoff -Every 0
Add-PSMidiQueueMessage -Message $chordAoff -Every 0

Add-PSMidiQueueMessage -Message $chordCoff -Every 16
Add-PSMidiQueueMessage -Message $chordEoff -Every 16
Add-PSMidiQueueMessage -Message $chordGoff -Every 16

Add-PSMidiQueueMessage -Message $chordFoff -Every 32
Add-PSMidiQueueMessage -Message $chordGoff -Every 32
Add-PSMidiQueueMessage -Message $chordCoff -Every 32

Add-PSMidiQueueMessage -Message $chordEoff -Every 48
Add-PSMidiQueueMessage -Message $chordAoff -Every 48
Add-PSMidiQueueMessage -Message $chordC2off -Every 48
#endregion




#region moreDrumNotes
$realKickon = New-PSMidiMessage -Note 'C' -Octave 1 -MidiChannel 5 -MessageStatus NoteOn
$realKickoff = New-PSMidiMessage -Note 'C' -Octave 1 -MidiChannel 5 -MessageStatus NoteOff

$snareon = New-PSMidiMessage -Note 'D' -Octave 1 -MidiChannel 5 -MessageStatus NoteOn
$snareoff = New-PSMidiMessage -Note 'D' -Octave 1 -MidiChannel 5 -MessageStatus NoteOff


0..63 | % {
    if (($_ % 4) -eq 0) {
        Add-PSMidiQueueMessage -Message $realKickon -Every $_
    }
    elseif (($_ % 4) -eq 1) {
        Add-PSMidiQueueMessage -Message $realKickoff -Every $_
    }
    elseif (($_ % 4) -eq 2) {
        Add-PSMidiQueueMessage -Message $realKickon -Every $_
        Add-PSMidiQueueMessage -Message $snareon -Every $_
    }
    elseif (($_ % 4) -eq 3) {
        Add-PSMidiQueueMessage -Message $realKickoff -Every $_
        Add-PSMidiQueueMessage -Message $snareoff -Every $_
    }
}
#endregion





# send-PSMidiMessage -Connection $connection -Message $snareon





# send-PSMidiMessage -Connection $connection -Message $snareoff


Stop-PSMidiQueue
Get-Variable -Name *Off | % { send-PSMidiMessage -Connection $connection -Message $_.Value }

Clear-PSMidiQueue
