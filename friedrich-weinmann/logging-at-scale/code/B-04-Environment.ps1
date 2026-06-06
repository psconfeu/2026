# failsafe
return

#----------------------------------------------------------------------------#
#                           Scenario: Environment                            #
#----------------------------------------------------------------------------#

Get-PSFConfig '*.conference.*'
Get-PSFConfig '*.conference.*' | Register-PSFConfig -Scope EnvironmentSimple

#-> Lets do this:
$job = Start-Job -ScriptBlock {
	Write-PSFMessage Starting
	Write-PSFMessage Done
}
$job
$job | Receive-Job
$job | Remove-Job

#-> Second Attempt
$job = Start-Job -ScriptBlock {
	Write-PSFMessage Starting
	Write-PSFMessage Done
	Wait-PSFMessage
	Get-ChildItem env:PSF*
}
$job
$job | Receive-Job
$job | Remove-Job
<#
PSF_LoggingProvider.eventlog.conference.Enabled            Bool:true
PSF_PSFramework.Logging.EventLog.conference.LogName        String:PSFramework
PSF_PSFramework.Logging.EventLog.conference.Source         String:Conference
#>

# Next: Scenario: Your Own Thing
code "$presentationRoot\B-05-CustomProvider.ps1"