[CmdletBinding()]
param (
	[string]
	$Department = 'AllUsers'
)

$logPath = "C:\Temp\demo\simple.log"

"Starting Script" | Set-Content -Path $logPath

"Retrieving users from Entra" | Add-Content -Path $logPath
$users = Invoke-EntraRequest -Path users
"$($users.Count) users found" | Add-Content -Path $logPath
foreach ($user in $users) {
	"Updating department for user $($user.UserPrincipalName) to $($Department)" | Add-Content -Path $logPath
	# We may not actually want to do this for a demo script
	# Set-MgUser -UserId $user.Id -Department $Department
}

"Script completed" | Add-Content -Path $logPath