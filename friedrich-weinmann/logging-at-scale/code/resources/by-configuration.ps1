[CmdletBinding()]
param (
	
)

$ErrorActionPreference = 'Stop'
trap {
	Write-Warning "Script failed: $_"
	Get-PSFLoggingProviderInstance | Disable-PSFLoggingProvider
	throw $_
}

Import-PSFConfig -Schema Psd1 -Path "$PSScriptRoot\config.psd1"
Wait-PSFMessage

#region Functions

#endregion Functions

Write-PSFMessage -Message "Starting Script"

Write-PSFMessage -Message "Retrieving users from Entra"
$users = Invoke-EntraRequest -Path users
Write-PSFMessage -Message "$($users.Count) users found"
foreach ($user in $users) {
	Write-PSFMessage -Message "Updating department for user $($user.UserPrincipalName) to $($Department)" -Target $user.UserPrincipalName
	# We may not actually want to do this for a demo script
	# Set-MgUser -UserId $user.Id -Department $Department
}

Write-PSFMessage -Message "Script completed"

Get-PSFLoggingProviderInstance | Disable-PSFLoggingProvider