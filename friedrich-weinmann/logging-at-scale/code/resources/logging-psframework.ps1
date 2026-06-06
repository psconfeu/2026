#requires -Modules PSFramework
[CmdletBinding()]
param (
	[string]
	$Department = 'AllUsers',

	[string]
	$LogPath = "C:\Temp\demo\psflog.csv"
)

$ErrorActionPreference = 'Stop'
trap {
	Write-PSFMessage -Level Warning -Message "Script failed" -ErrorRecord $_
	Disable-PSFLoggingProvider -Name logfile -InstanceName $script:scriptname
	throw $_
}

$script:scriptname = "demo-script"

$logging = @{
	Name         = "logfile"
	InstanceName = $script:scriptname
	FilePath     = $LogPath
	Enabled      = $true
	Wait         = $true
}
Set-PSFLoggingProvider @logging

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

Disable-PSFLoggingProvider -Name logfile -InstanceName $script:scriptname