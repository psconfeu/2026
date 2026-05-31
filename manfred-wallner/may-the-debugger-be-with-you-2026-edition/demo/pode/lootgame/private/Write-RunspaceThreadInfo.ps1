function Write-RunspaceThreadInfo {
  param(
    [Parameter(Mandatory)]
    [string]$Purpose
  )

  $runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace
  $runspaceId = if ($null -ne $runspace) { $runspace.Id } else { '<none>' }
  $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId

  Write-Host ('[debug-attach] runspaceId={0} threadId={1} purpose={2}' -f $runspaceId, $threadId, $Purpose)
}
