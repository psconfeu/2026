# Failsafe
return

#----------------------------------------------------------------------------#
#                  What the hell broke 2,500,000 users ago?                  #
#----------------------------------------------------------------------------#

$resourcePath = 'C:\Code\github\P2026-PSConfEU-ZeroTrustAssessment\code\resources'

<#
Why?
Challenges
#>

# Logging
#----------

Write-PSFMessage -Message Demo
Get-PSFMessage | Select-Object -Last 1
Get-PSFMessage | Select-Object -Last 1 | fl

#-> Logging
Set-PSFLoggingProvider -Name logfile -InstanceName ZTLog -FilePath C:\Temp\demo\ztlog.csv -Enabled $true -Wait
Write-PSFMessage -Message 'Hello {0}' -StringValues Fred -Tag greeting, demo -Target Fred
code C:\Temp\demo\ztlog.csv

#-> Other Targets
Set-PSFLoggingProvider -Name eventlog -InstanceName ZTEvent -LogName ZeroTrust -Source Assessment -Enabled $true
Set-PSFLoggingProvider -Name AzureLogAnalytics -InstanceName ZTAZLA -WorkspaceId $wsid -SharedKey $key -Enabled $true
Get-PSFLoggingProvider


# Getting the Info that is needed
#----------------------------------

New-PSFSupportPackage -Path .
Expand-Archive -DestinationPath . -Path .\powershell_support_pack_2026_06_02-11_32_16.zip
$data = Import-PSFClixml .\powershell_support_pack_2026_06_02-11_32_16.cliDat
$data.Messages
$data.Modules
$data.Assemblies
$data.History
$data.ConsoleBuffer


<#
Oversharing
AI Skill
#>
code "$resourcePath\skill.md"

<#
Docs: https://psframework.org/docs/PSFramework/Logging/overview
Talk: On Thursday
#>

#-> Next: Releasing the Break
code "$presentationRoot\A-05-Performance.ps1"