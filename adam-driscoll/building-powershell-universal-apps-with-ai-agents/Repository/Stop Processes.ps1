param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the Process ID (PID) of the process to stop.")]
    $ProcessId
)

Write-Host "Stopping process with PID: $ProcessId"