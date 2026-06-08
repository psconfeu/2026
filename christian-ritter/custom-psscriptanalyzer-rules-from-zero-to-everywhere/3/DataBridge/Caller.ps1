Add-Type @"
public static class DataBridge {
    public static string Bridge = "";
}
"@
cd .\3\DataBridge
# Example usage of the DataBridge in an active script
invoke-scriptanalyzer -path .\ActiveScript.ps1 -customRulePath .\Rules\* 

$timer = New-Object Timers.Timer 3000
[void](Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier "Timer" -Action {
    invoke-scriptanalyzer -path .\ActiveScript.ps1 -customRulePath .\Rules\* 
})
$timer.Start()