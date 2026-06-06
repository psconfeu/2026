# Copyright: (c) 2024, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function New-ScheduledTaskSession {
    <#
    .SYNOPSIS
    Creates a PSSession for a process running as a scheduled task.

    .DESCRIPTION
    Creates a PSSession that can be used to run code inside a scheduled task
    context. This context can be used to bypass issues like a network logon
    not being able to access the Windows Update API, solving the double hop
    problem or just to run code under SYSTEM.

    The session can be used alongside the builtin cmdlets like Invoke-Command
    or Enter-PSSession to use the session to run a command non-interactively
    or through an interactive session. Once the session is no longer needed it
    should be cleaned up with Remove-PSSession.

    By default the task will run as the current user using S4U. This is like
    running a task with the setting "Run whether user is logged on or not"
    without storing the password. Use '-UserName' to specify any other well
    known service accounts like 'SYSTEM', 'LocalService', 'NetworkService',
    or to specify a gMSA account. To run as another user, or the current user
    with access to network resources, use the '-Credential' parameter to
    specify the credentials to run as. It is also possible to run the task in
    an interactive session from session 0. This switch will create a task that
    is set to 'Run only when user is logged on' for any user that is logged on
    the host allowing the code to be run in an actual interactive session. If
    set but there are no interactive sessions the task will timeout while
    waiting for the process to start.

    .PARAMETER PowerShellPath
    Override the PowerShell executable used, by default will use the current
    PowerShell executable.

    .PARAMETER UserName
    Runs the scheduled task as the user specified. This can be set to well
    known service accounts like 'SYSTEM', 'LocalService', or 'NetworkService'
    to run as those service accounts. It can also be set to a gMSA that ends
    with '$' in the name to run as that gMSA account. Otherwise this will
    attempt to run using S4U which only works for the current user.

    If using a gMSA, the gMSA must be configured to allow the current computer
    account the ability to retrieve its password.

    .PARAMETER Credential
    Runs the scheduled task as the user specified by the credentials. The
    process will be able to access network resources or do other tasks that
    require credentials like access DPAPI secrets. The user specified must have
    batch logon rights.

    .PARAMETER Interactive
    Runs the scheduled task as an interactive user. This sets the task
    principal as 'BUILTIN\Users' and set to run only when user is logged on.
    This is useful for running a process on an interactive desktop but will
    only work if there is an existing interactive session present.

    .PARAMETER OpenTimeout
    The timeout, in seconds, to wait for the PowerShell process to be created
    by the task scheduler and also to connect to the named pipe it creates. As
    each operation are separate the total timeout could potentially be double
    the value specified here.

    .PARAMETER RunLevel
    The privilege level to run the scheduled task process as. Set to Highest
    to run it with the full privileges of the user. Set to Lowest to run as
    the limited/lowest privileges of the user. If UAC is disabled or the user
    is not affected by UAC (builtin Administrator account), this value does
    nothing.

    .EXAMPLE
        $s = New-ScheduledTaskSession
        Invoke-Command $s { whoami /all }
        $s | Remove-PSSession

    Runs task as current user and closes the session once done.

    .EXAMPLE

        $s = New-ScheduledTaskSession -UserName SYSTEM
        Invoke-Command $s { whoami }
        $s | Remove-PSSession

    Runs task as SYSTEM.

    .EXAMPLE

        $s = New-ScheduledTaskSession -UserName myGMSA$
        Invoke-Command $s { whoami }
        $s | Remove-PSSession

    Runs task as a gMSA account, note the username ends with '$'.

    .EXAMPLE

        $s = New-ScheduledTaskSession -Credential user
        Invoke-Command $s { whoami }
        $s | Remove-PSSession

    Runs task as 'user', this will prompt for the password for user.

    .EXAMPLE

        $s = New-ScheduledTaskSession
        Enter-PSSession $s

    Enters an interactive PSSession for the started scheduled task process.

    .EXAMPLE

        $s = New-ScheduledTaskSession -Interactive
        Invoke-Command $s {
            Get-Process -Id $pid | Select-Object -Property ProcessName, Id, SessionId
        }
        $s | Remove-PSSession

    Runs task as the interactive logon session. The caller of
    New-ScheduledTaskSession will be running in session 0 like through ssh,
    winrm, service, etc but the session will be spawned on the interactive
    session of an existing logon user.

    .NOTES
    This cmdlet requires admin permissions to create the scheduled task.
    #>
    [OutputType([System.Management.Automation.Runspaces.PSSession])]
    [CmdletBinding(DefaultParameterSetName = "UserName")]
    param (
        [Parameter()]
        [string]
        $PowerShellPath,

        [Parameter(ParameterSetName = "UserName")]
        # [ArgumentCompleter("LocalService", "NetworkService", "SYSTEM")]  # Needs pwsh 7+
        [string]
        $UserName,

        [Parameter(ParameterSetName = "Credential")]
        [System.Management.Automation.Credential()]
        [PSCredential]
        $Credential,

        [Parameter(ParameterSetName = "Interactive")]
        [switch]
        $Interactive,

        [Parameter()]
        [int]
        $OpenTimeout = 30,

        [Parameter()]
        [ValidateSet("Highest", "Limited")]
        [string]
        $RunLevel = 'Highest'
    )

    $ErrorActionPreference = 'Stop'

    # Use a unique GUID to identify the process uniquely after we start the task.
    $powershellId = (New-Guid).ToString()
    $taskName = "New-ScheduledTaskSession-$powershellId"

    # PowerShell 7.3 created a public way to build a PSSession but WinPS needs
    # to use reflection to build the PSSession from the Runspace object.
    $createPSSession = if ([System.Management.Automation.Runspaces.PSSession]::Create) {
        {
            [System.Management.Automation.Runspaces.PSSession]::Create($args[0], $taskName, $null)
        }
    }
    else {
        $remoteRunspaceType = [PSObject].Assembly.GetType('System.Management.Automation.RemoteRunspace')
        $pssessionCstr = [System.Management.Automation.Runspaces.PSSession].GetConstructor(
            'NonPublic, Instance',
            $null,
            [type[]]@($remoteRunspaceType),
            $null)

        { $pssessionCstr.Invoke(@($args[0])) }
    }

    if (-not $PowerShellPath) {
        $PowerShellPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        # wsmprovhost is used in a WSMan PSRemoting target, we need to change
        # that to the proper executable.
        $systemRoot = $env:SystemRoot
        if (-not $systemRoot) {
            $systemRoot = 'C:\Windows'
        }
        if ($PowerShellPath -in @(
            "$systemRoot\system32\wsmprovhost.exe"
            "$systemRoot\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
        )) {
            $executable = if ($IsCoreCLR) {
                'pwsh.exe'
            }
            else {
                'powershell.exe'
            }

            $PowerShellPath = Join-Path $PSHome $executable
        }
    }
    # Resolve the absolute path for PowerShell for the CIM filter to work.
    if (Test-Path -LiteralPath $PowerShellPath) {
        $PowerShellPath = (Get-Item -LiteralPath $PowerShellPath).FullName
    }
    elseif ($powershellCommand = Get-Command -Name $PowerShellPath -CommandType Application -ErrorAction SilentlyContinue) {
        $PowerShellPath = $powershellCommand.Path
    }
    else {
        $exc = [System.ArgumentException]::new("Failed to find PowerShellPath '$PowerShellPath'")
        $err = [System.Management.Automation.ErrorRecord]::new(
            $exc,
            'FailedToFindPowerShell',
            'InvalidArgument',
            $PowerShellPath)
        $PSCmdlet.WriteError($err)
        return
    }

    $powershellArg = "-WindowStyle Hidden -NoExit -Command '$powershellId'"
    Write-Verbose -Message "Creating scheduled task to run '$PowerShellPath' with the ID $powershellId"
    $action = New-ScheduledTaskAction -Execute $PowerShellPath -Argument $powershellArg

    $taskParams = @{
        Action = $action
        Force = $true
        Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        TaskName = $taskName
        ErrorAction = 'Stop'
    }

    if ($Interactive) {
        Write-Verbose -Message "Setting task to run with interactive session"
        $group = [System.Security.Principal.SecurityIdentifier]::new(
            [System.Security.Principal.WellKnownSidType]::BuiltinUsersSid,
            $null).Translate([System.Security.Principal.NTAccount]).Value
        $principal = New-ScheduledTaskPrincipal -GroupId $group -RunLevel $RunLevel
        $taskParams.Principal = $principal
    }
    elseif ($Credential) {
        Write-Verbose -Message "Setting task to run with credentials for '$($Credential.UserName)'"
        $taskParams.User = $Credential.UserName
        $taskParams.Password = $Credential.GetNetworkCredential().Password
        $taskParams.RunLevel = $RunLevel
    }
    else {
        if ($UserName) {
            $sid = ([System.Security.Principal.NTAccount]$UserName).Translate(
                [System.Security.Principal.SecurityIdentifier])
        }
        else {
            $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
        }

        # Normalise the username from the SID.
        $UserName = $sid.Translate([System.Security.Principal.NTAccount]).Value
        $logonType = 'S4U'
        if ($sid.Value -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
            # SYSTEM, LocalService, NetworkService
            $logonType = 'ServiceAccount'
        }
        elseif ($UserName.EndsWith('$')) {
            # gMSA
            $logonType = 'Password'
        }

        $principal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType $logonType -RunLevel $RunLevel
        $taskParams.Principal = $principal
        Write-Verbose -Message "Setting task to run as '$($principal.UserId)' with logon type $($principal.LogonType)"
    }

    $task = Register-ScheduledTask @taskParams
    try {
        $stopProc = $true
        $procId = 0
        $runspace = $null

        $task | Start-ScheduledTask

        # There's no API to get the running PID of a task so we use CIM to
        # enumerate the processes and find the one that matches our unique
        # command identifier.
        $wqlFilter = "ExecutablePath = '$($PowerShellPath -replace '\\', '\\')' AND CommandLine LIKE '% -WindowStyle Hidden -NoExit -Command \'$powershellId\''"
        $cimParams = @{
            ClassName = 'Win32_Process'
            Filter = $wqlFilter
            Property = 'ProcessId'
        }
        $start = Get-Date
        while (-not ($proc = Get-CimInstance @cimParams)) {
            if (((Get-Date) - $start).TotalSeconds -gt $OpenTimeout) {
                throw "Timeout waiting for PowerShell process to start"
            }
            Start-Sleep -Seconds 1
        }
        $procId = [int]$proc.ProcessId

        Write-Verbose "Found spawned process $procId - attempting to open"
        $typeTable = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()
        $connInfo = [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new($procId)
        $connInfo.OpenTimeout = $OpenTimeout * 1000
        $runspace = [RunspaceFactory]::CreateRunspace($connInfo, $host, $typeTable)
        $runspace.Open()

        Write-Verbose "Registering handler to stop the process on closing the PSSession"
        $null = Register-ObjectEvent -InputObject $runspace -EventName StateChanged -MessageData $procId -Action {
            if ($EventArgs.RunspaceStateInfo.State -in @('Broken', 'Closed')) {
                Unregister-Event -SourceIdentifier $EventSubscriber.SourceIdentifier
                Stop-Process -Id $Event.MessageData -Force
            }
        }
        $stopProc = $false

        Write-Verbose "Runspace opened, creating PSSession object"
        & $createPSSession $runspace
    }
    catch {
        if ($stopProc -and $procId) {
            Stop-Process -Id $procId -Force
        }
        if ($runspace) {
            $runspace.Dispose()
        }

        $err = [System.Management.Automation.ErrorRecord]::new(
            $_.Exception,
            'FailedToOpenSession',
            'NotSpecified',
            $null)
        $PSCmdlet.WriteError($err)
    }
    finally {
        $task | Unregister-ScheduledTask -Confirm:$false
    }
}
