#requires -version 7.6
#Built using .Net 10 - requires 7-6


# Start by setting up a listening synth using reaper
# & "..\REAPER (arm64)\reaper.exe" 'PSConf\MusicalPowerShell\Demo1\demo1.rpp'

# SDK also includes a CLI and a GUI
& "C:\Program Files\Windows MIDI Services\Tools\Settings\MidiSettings.exe"


# The main midi module
Import-Module WindowsMidiServices
Get-Command -module WindowsMidiServices



# Load the runtimes - load types, start service (if not already on) 
Start-Midi


# Get all endpoints
$EDI = Get-MidiEndpointDeviceInfoList


# Create new endpoints
New-MidiLoopbackEndpointPair -LoopbackBaseName "PSConf$(Get-Random -Minimum 1000 -Maximum 1000000)" -UniqueIdentifier $((New-Guid).guid) -Description 'PSConf demo'




#Get endpoint info
$endpointDeviceId = $EDI[1].EndpointDeviceId
Get-MidiEndpointDeviceInfo $endpointDeviceId




# A session is what sends or receives messages
$session = Start-MidiSession "PSConf Demo Session"



# Finally, set up a connection to talk to the enpoint
$connection = Open-MidiEndpointConnection $session $endpointDeviceId




# Sending a message - the SDK example
$messages = (0x40905252, 0x02001111), (0x40805252, 0x02000000), 0x25971234

foreach ($message in $messages) {
    Write-Host "Sending MIDI message" -ForegroundColor Cyan

    Send-MidiMessage $connection $message -Timestamp 0

    Start-Sleep -Seconds 1
}

