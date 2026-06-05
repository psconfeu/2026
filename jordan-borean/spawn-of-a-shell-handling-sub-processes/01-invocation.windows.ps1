Demo "Console executables are blocking" {
    Description "Running a console exe through direct invocation waits until it exits"

    Code {
        Measure-Command {
            pwsh -Command 'Start-Sleep -Seconds 3'
        }
    }
}

Demo "GUI executables are non-blocking" {
    Description "Running a gui exe through direct invocation does not block"

    Code {
        Measure-Command {
            notepad $PSCommandPath
        }
    }
}

Demo "Start-Process -Wait for GUI executable" {
    Description "You can wait for a GUI executable using Start-Process -Wait"

    Code {
        Measure-Command {
            Start-Process notepad.exe -ArgumentList "`"$PSCommandPath`"" -Wait
        }
    }
}

Demo "Start-Process -Wait on grandchildren" {
    Description "Start-Process -Wait will wait for the child process but any it spawns as well*"

    Code {
        # * Msix/Appx packages can play havoc with this
        Start-Process powershell.exe -Wait
    }
}

Demo "Start-Process | Wait-Process" {
    Description "Start-Process | Wait-Process waits on just the immediate process"

    Code {
        Start-Process powershell.exe -PassThru | Wait-Process
    }
}

Demo "Start-Process no wait" {
    Description "Show how Start-Process runs process in background"

    Code {
        $proc = Start-Process pwsh.exe -ArgumentList '-NoExit -Command 123' -PassThru

        Get-Process -Id $proc.Id
    }
}

Demo "Invoke-Command job" {
    Description "Show how process jobs can kill child processes"

    Code {
        $proc = Invoke-Command -ComputerName localhost -ScriptBlock {
            Start-Process pwsh.exe -ArgumentList '-NoExit -Command 123' -PassThru
            Start-Sleep -Seconds 1
        }

        Start-Sleep -Seconds 1
        Get-Process -Id $proc.Id
    }
}

Demo "Invoke-Command job escaping" {
    Description "Shows how to escape the process job and outlive it"

    Code {
        $res = Invoke-Command -ComputerName localhost -ScriptBlock {
            Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
                CommandLine = "pwsh.exe -NoExit -Command 123"
            }
            Start-Sleep -Seconds 1
        }

        if ($res.ReturnValue -ne 0) {
            throw "Failed to start process $($res.ReturnValue)"
        }

        Start-Sleep -Seconds 1
        Get-Process -Id ([int]$res.ProcessId)
    }
}

# Demo "Task Scheduler Session - Part 1" {
#     Description "Part 1 of PSRemoting based task scheduler session, shows how NETWORK logons can stop actions unexpectedly"

#     Code {
#         # Works in normal INTERACTIVE logon
#         (New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired

#         Invoke-Command -ComputerName localhost -ScriptBlock {
#             # Fails in NETWORK logon
#             (New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired
#         }
#     }
# }

# Demo "Task Scheduler Session - Part 2" {
#     Description "Part 2 of PSRemoting based task scheduler session, shows how to escape into a task scheduler process"

#     Code {
#         # https://gist.github.com/jborean93/0952263a902b8008cda506752a2f0a49
#         . "$PSScriptRoot\New-ScheduledTaskSession.ps1"
#         $newScheduledTaskSession = ${function:New-ScheduledTaskSession}

#         Invoke-Command -ComputerName localhost -ScriptBlock {
#             ${function:New-ScheduledTaskSession} = $using:newScheduledTaskSession

#             $session = New-ScheduledTaskSession
#             try {
#                 Invoke-Command -Session $session -ScriptBlock {
#                     # Anything in here is run in the task scheduler logon
#                     # which is a BATCH logon.
#                     (New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired
#                 }
#             }
#             finally {
#                 $session | Remove-PSSession
#             }
#         }
#     }
# }

# Demo "Parent process trickery" {
#     Description "Shows how to run something in the user context of a target process"

#     Code {
#         # https://github.com/jborean93/ProcessEx
#         Import-Module -Name ProcessEx -ErrorAction Stop

#         whoami

#         Start-Service TrustedInstaller
#         $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'"

#         $startInfo = New-StartupInfo -ParentProcess $service.ProcessId
#         Invoke-ProcessEx whoami /all -StartupInfo $startInfo
#     }
# }

# Demo "Parent process through PSRemoting" {
#     Description "Shows how to custom parent process context's but with PSRemoting over the top"

#     Code {
#         # https://github.com/jborean93/ProcessEx
#         Import-Module -Name ProcessEx -ErrorAction Stop

#         Start-Service TrustedInstaller
#         $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'"

#         $startInfo = New-StartupInfo -ParentProcess $service.ProcessId -WindowStyle Hide
#         $proc = Start-ProcessEx powershell.exe -StartupInfo $startInfo -PassThru
#         try {
#             $connInfo = [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new(
#                 $proc.Id)
#             $runspace = [RunspaceFactory]::CreateRunspace($connInfo)
#             $runspace.Open()
#             $session = [System.Management.Automation.Runspaces.PSSession]::Create(
#                 $runspace, $null, $null)

#             Invoke-Command -Session $session -ScriptBlock {
#                 whoami /all
#             }

#             $session | Remove-PSSession
#         }
#         finally {
#             ${runspace}?.Dispose()
#             Stop-Process -Id $proc.Id -Force
#         }
#     }
# }
