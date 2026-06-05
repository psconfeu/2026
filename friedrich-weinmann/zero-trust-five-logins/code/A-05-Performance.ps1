# Failsafe
return

#----------------------------------------------------------------------------#
#                    But it works just fine in my lab...                     #
#----------------------------------------------------------------------------#

# General Performance & Scaling Tuning
#---------------------------------------

<#
Profiler (Jakub Jares):
https://www.powershellgallery.com/packages/Profiler
#>


# Some Tweaks I did
#--------------------

#-> Array Addition
#-------------------

$numbers = 1..50000
$array = @()
foreach ($number in $numbers) {
	$array += $number
}
# Instead:
$numbers = 1..50000
$array = foreach ($number in $numbers) {
	$number
}

#-> The return statement
#-------------------------
# Please don't:
function Get-UserStatistics {
	[CmdletBinding()]
	param ()

	$users = Get-MgUser
	$results = foreach ($user in $users) {
		# Gather a lot more data
		# ...
		# ...

		[PSCustomObject]@{
			SamAccountName = $user.SamAccountName
			Mail = $user.PrimarySmtpAddress
			MailboxSize = $mailbox.Size
			# <lots more data>
		}
	}

	return $results
}
Get-UserStatistics | Export-Csv -Path .\users.csv

# What it should have been
function Get-UserStatistics {
	[CmdletBinding()]
	param ()

	Get-MgUser | ForEach-Object {
		# Gather a lot more data
		# ...
		# ...

		[PSCustomObject]@{
			SamAccountName = $_.SamAccountName
			Mail = $_.PrimarySmtpAddress
			MailboxSize = $mailbox.Size
			# <lots more data>
		}
	}
}
Get-UserStatistics | Export-Csv -Path .\users.csv

# Quick Demo to help Visualize
function Get-NumbersSlowly {
	[CmdletBinding()]
	param (
		[int]
		$Count = 3
	)

	foreach ($number in 1..$Count) {
		Write-PSFMessage -Level Host -Message 'Sending number <c="Green">{0}</c>' -StringValues $number
		$number
		Start-Sleep -Seconds 1
	}
}
Get-NumbersSlowly | ForEach-Object {
	Write-PSFMessage -Level Host 'Receiving number <c="Green">{0}</c>' -StringValues $_
}

#-> Graph Batching
#-------------------

Connect-EntraService -ClientID Graph
$users = Invoke-EntraRequest -Path users
$users.Count
foreach ($user in $users) {
	Invoke-EntraRequest -Path "users/$($user.id)/authentication/methods"
}

<#
Batching:
https://learn.microsoft.com/en-us/graph/json-batching?tabs=http
#>
# Example Request
<#
POST https://graph.microsoft.com/v1.0/$batch
Accept: application/json
Content-Type: application/json

{
  "requests": [
    {
      "id": "1",
      "method": "GET",
      "url": "/me/memberOf"
    },
    {
      "id": "2",
      "method": "GET",
      "url": "/me/planner/tasks"
    },
    {
      "id": "3",
      "method": "DELETE",
      "url": "/groups/0e226165-c685-41ce-8bfc-df8360ab325d"
    },
    {
      "id": "4",
      "url": "/users/161ab652-cdbc-490d-82a4-0ada1f0db247/getPasswordSingleSignOnCredentials",
      "method": "POST",
      "body": {},
      "headers": {"Content-Type": "application/json"}
    },
    {
      "id": "5",
      "url": "users?$select=id,displayName,userPrincipalName&$filter=city eq null&$count=true",
      "method": "GET",
      "headers": {
        "ConsistencyLevel": "eventual"
      }
    }
  ]
}
#>
Invoke-EagBatchRequest -Path "users/{0}/authentication/methods" -ArgumentList $users -Properties id

Invoke-EagBatchRequest -Path "users/{0}/authentication/methods" -ArgumentList $users -Properties id -Matched
$result = Invoke-EagBatchRequest -Path "users/{0}/authentication/methods" -ArgumentList $users -Properties id -Matched
$result[0]
$result[0].Argument
$result[0].Result
<#
Demo Modules:
EntraAuth
EntraAuth.Graph
#>

#-> Caching
#------------

# Why Cache Graph Requests
# Why is that a problem with Runspaces?

$cache = Set-PSFDynamicContentObject -Name "ZtAssessment.GraphCache" -Dictionary -PassThru
$cache
$cache.Value["Start"] = 42
$cache.Value["Start"]

1..20 | Invoke-PSFRunspace -ThrottleLimit 3 -ScriptBlock {
	$cache = Set-PSFDynamicContentObject -Name "ZtAssessment.GraphCache" -Dictionary -PassThru
	$cache.Value["Number-$_"] = $_ * $cache.Value["Start"]
	if ($cache.Value["Number-$($_-10)"]) { $cache.Value["Number-$($_)"] -= $cache.Value["Number-$($_-10)"] }
	Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 80)
} -ImportPSFramework
$cache.Value

# Is Caching always a good idea?
Set-PSFConfig -Module ZeroTrustAssessment -Name 'Graph.DisableCache' -Value $true

# More on Caching:
# Wednesday Session: Caching

#-> Next: Configuration
code "$presentationRoot\A-06-Configuration.ps1"