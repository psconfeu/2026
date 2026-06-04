#region prepare
import-module WindowsMidiServices
Import-Module \GitHub\bjompen\PSMidi\Source\PSMidi
$sdkinfo = Start-Midi

$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI.Where({ $_.Name -like "Launchkey MK4*" }).EndpointDeviceId

$session = Start-MidiSession "Powershell Keyboard keyboard"
$connection = Open-MidiEndpointConnection $session $endpointDeviceId
#endregion



# ASCII table has 127 characters.. Midi has 127 keys... I see a pattern..
& 'firefox.exe' 'https://www.ascii-code.com/'
# Capital A has ASCII indes 65




# Standard keyboard has 104 keys... 
# That means we have 23 Midi keys more than a keyboard..
& 'firefox.exe' 'https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes'
# 0x41 - a key
# 0x10 - shift
# 0x10, 0x41 - Capital A

sendvirtualKeyboard -IntIndex 65




$eventHandlerAction = {
    $words = Get-MidiMessageInfo $EventArgs.Words
    if (($words.MessageName -like "*Note On") -and ($words.WordsHex -notlike "*00") -and ($words.WordsHex -notlike "*007F")) {
        $words
        $keyValueHex = $words.WordsHex.Substring(4,2)
        $keyValueInt = [uint32]"0x$keyValueHex"
        SendVirtualKeyboard -IntIndex $keyValueInt
    }
}

$job = Register-ObjectEvent -SourceIdentifier "OnMessageReceivedHandler" -InputObject $connection -EventName "MessageReceived" -Action $eventHandlerAction

# # just spin until a key is pressed
do {
    # get the output from our background job
    $r = Receive-Job -Job $job

    if (($r.MessageName -like "*Note On") -and ($r.WordsHex -notlike "*00")){
        # $keyValueHex = $r.WordsHex.Substring(4,2)
        # $keyValueInt = [uint32]"0x$keyValueHex"
        # $keyValueInt
        $r
    }
} until ([System.Console]::KeyAvailable)



Get-EventSubscriber | Unregister-Event
Get-Job | Stop-Job
Get-Job | Remove-Job

