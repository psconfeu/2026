# failsafe
return

#----------------------------------------------------------------------------# 
#                            PSFramework Logging                             # 
#----------------------------------------------------------------------------# 

$resourcePath = "$presentationRoot\resources"

# https://psframework.org

# Messsage & in-memory
Write-PSFMessage -Message "Hello 1"
Write-PSFMessage -Message "Hello 2" -Verbose

#-> Levels
Write-PSFMessage -Level Host -Message "Hello 3"
Write-PSFMessage -Level Warning -Message "Hello 4"

Get-PSFMessage
Get-PSFMessage | Select-Object -Last 1 | Format-List

#-> Values, Tags & Targets
Write-PSFMessage -Message 'Hello {0}' -StringValues Fred -Target Fred -Tag Greeting
Get-PSFMessage | Select-Object -Last 1 | Format-List

# Providers
Get-PSFLoggingProvider

#-> The Default Log
Get-PSFConfigValue -FullName PSFramework.Logging.FileSystem.LogPath
Get-PSFConfig -FullName PSFramework.Logging.FileSystem.*

#-> A Logfile
Set-PSFLoggingProvider -Name logfile -InstanceName MyDemoCsv -FilePath C:\temp\demo\mylog.csv -Enabled $true -Wait
Write-PSFMessage "Test 1"
Write-PSFMessage "Test 2"
Write-PSFMessage "Test 3"
code C:\temp\demo\mylog.csv

# Provider Instances
Get-PSFLoggingProviderInstance
#-> Two Logfiles
$param = @{
	Name         = 'logfile'
	InstanceName = 'MyDemoTrace'
	FilePath     = 'C:\temp\demo\mylog.trace'
	FileType     = 'CMTrace'
	MaxLevel     = 4
	Enabled      = $true
	Wait         = $true
}
Set-PSFLoggingProvider @param
code C:\temp\demo\mylog.trace
Write-PSFMessage "Test 4"
Write-PSFMessage "Test 5" -Level Critical
Get-PSFLoggingProviderInstance

# Eventlog?
Set-PSFLoggingProvider -Name eventlog -InstanceName DemoEvents -LogName PSFramework -Source Conference -Enabled $true
Write-PSFMessage 'Message'

# Runspaces & Logging
1..20 | Invoke-PSFRunspace -ScriptBlock {
	Write-PSFMessage "Test: $_"
	Start-Sleep -Milliseconds 100
} -ImportPSFramework
Get-PSFMessage

# Disabling
Disable-PSFLoggingProvider -Name eventlog -InstanceName DemoEvents
Get-PSFLoggingProviderInstance | Disable-PSFLoggingProvider

# Example Script
code "$resourcePath\logging-psframework.ps1"
& "$resourcePath\logging-psframework.ps1"
code "C:\Temp\demo\psflog.csv"

# Next: Architecture
code "$presentationRoot\A-03-Architecture.ps1"