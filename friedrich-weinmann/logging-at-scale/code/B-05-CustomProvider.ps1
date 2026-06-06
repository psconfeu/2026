# failsafe
return

#----------------------------------------------------------------------------#
#                         Scenario: Custom Provider                          #
#----------------------------------------------------------------------------#

$resourcePath = "$presentationRoot\resources"

code "$resourcePath\ContosoTools\ContosoTools.psm1"

Import-Module "$resourcePath\ContosoTools\ContosoTools.psd1"
Set-PSFLoggingProvider -Name FastFile -InstanceName MyTask -Path 'C:\Temp\Demo\logs\test-fast.log' -Enabled $true
Write-PSFMessage -Message "Test Message"
Get-Content 'C:\Temp\Demo\logs\test-fast.log' # File not found

#-> TO DO: Troubleshoot
Get-PSFLoggingError
Get-PSFLoggingError | fl

New-Item -Path C:\Temp\demo\logs -ItemType Directory
Set-PSFLoggingProvider -Name FastFile -InstanceName MyTask -Path 'C:\Temp\Demo\logs\test-fast.log' -Enabled $false
Set-PSFLoggingProvider -Name FastFile -InstanceName MyTask -Path 'C:\Temp\Demo\logs\test-fast.log' -Enabled $true
Write-PSFMessage -Message "Test Message"

code 'C:\Temp\Demo\logs\test-fast.log'

# Next: ???
code "$presentationRoot\C-01-Questions.ps1"