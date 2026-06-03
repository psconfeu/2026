#region pre
import-module WindowsMidiServices
Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi
$sdkinfo = Start-Midi

$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI[0].EndpointDeviceId

$session = Start-MidiSession "Powershell Musical script"
$connection = Open-MidiEndpointConnection $session $endpointDeviceId

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

    Chord([string] $Chord) {
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

    Chord([int] $MidiIndexNote) {
        if (($MidiIndexNote % 12) -in @(0, 2, 4, 5, 7, 9,11)) {
            $this.BaseChord = [NoteIndex]($MidiIndexNote % 12)
            $this.Alt = [string]::Empty
            $this.AltMidi = 0
        }
        else {
            $this.BaseChord = [NoteIndex](($MidiIndexNote % 12) - 1)
            $this.Alt = '#'
            $this.AltMidi = 1
        }
        $this.Octave = [math]::Floor(($MidiIndexNote / 12) - 2)
        $this.MidiNote = $MidiIndexNote
    }
}

#endregion

$index = gc \GitHub\bjompen\PSMidi\Source\Resources\KeyMap_sv-SE.csv | ConvertFrom-Csv -Delimiter ';'
$c = Get-Content '\PSConf\MusicalPowerShell\Demo5-KeyboardKeyboard\Demo5-3-MusicalScripts.ps1'
foreach ($a in $c.ToCharArray()) {
    $si = $index.Where({$_.Char -ceq $a}).IntIndex
    if ($si) {
        $pc = [Chord]::new([int]$si)
        Write-Host "Char >>$a<< - Note >>$($pc.BaseChord)<< - Octave >>$($pc.Octave)<<"
        New-PSMidiMessage -Note $pc.BaseChord -Octave $pc.Octave -MessageStatus NoteOn | Send-PSMidiMessage -Connection $connection
        start-sleep -Milliseconds 100
        New-PSMidiMessage -Note $pc.BaseChord -Octave $pc.Octave -MessageStatus NoteOff | Send-PSMidiMessage -Connection $connection
    }
}