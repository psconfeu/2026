#requires -Modules PSFramework
[CmdletBinding()]
param (
	[string]
	$LogRoot = 'C:\Temp\demo'
)

# Error Handling
$ErrorActionPreference = 'Stop'
trap {
	Write-PSFMessage -Level Warning -Message "Script failed" -ErrorRecord $_
	Disable-PSFLoggingProvider -Name logfile -InstanceName $script:_ScriptName
	New-PSFSupportPackage -TaskName $script:_ScriptName
	throw $_
}

# Logging
$script:_ScriptName = 'BeerTask2'
$paramSetPSFLoggingProvider = @{
	Name           = 'logfile'
	InstanceName   = $script:_ScriptName
	FilePath       = "$($LogRoot)\$($script:_ScriptName)-%Date%.csv"
	Enabled        = $true
	Wait           = $true
	ExcludeModules = 'BeerManager'
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider

Import-Module "$PSScriptRoot\BeerManager\BeerManager.psd1"

#region Functions
# To Do: Add implementing functions
#endregion Functions

Write-PSFMessage -Message "Starting Script"

# Main

Write-PSFMessage -Message "Retrieving users from Entra"
$users = Invoke-EntraRequest -Path users
Write-PSFMessage -Message "$($users.Count) users found"
foreach ($user in $users) {
	Write-PSFMessage -Message "Resolving beer for user $($user.UserPrincipalName)" -Target $user.UserPrincipalName
	Resolve-Beer -User $user.UserPrincipalName
}

Write-PSFMessage -Message "Script completed successfully"
Disable-PSFLoggingProvider -Name logfile -InstanceName $script:_ScriptName