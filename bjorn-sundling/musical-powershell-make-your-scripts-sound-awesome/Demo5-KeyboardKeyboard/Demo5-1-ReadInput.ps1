import-module WindowsMidiServices
$sdkinfo = Start-Midi

$EDI = Get-MidiEndpointDeviceInfoList
$endpointDeviceId = $EDI.Where({$_.Name -like "Launchkey MK4*"}).EndpointDeviceId

$session = Start-MidiSession "Powershell Keyboard keyboard"
$connection = Open-MidiEndpointConnection $session $endpointDeviceId


$eventHandlerAction = {
    Get-MidiMessageInfo $EventArgs.Words
}

$job = Register-ObjectEvent -SourceIdentifier "OnMessageReceivedHandler" -InputObject $connection -EventName "MessageReceived" -Action $eventHandlerAction

# just spin until a key is pressed
do {
    # get the output from our background job
    $r = Receive-Job -Job $job

    if (($r.MessageName -like "*Note On") -and ($r.WordsHex -notlike "*00")){
        $r
    }
} until ([System.Console]::KeyAvailable)


Get-EventSubscriber | Unregister-Event
get-Job | stop-Job
get-Job | remove-Job

