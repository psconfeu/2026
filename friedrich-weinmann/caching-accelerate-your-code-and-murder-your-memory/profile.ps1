function Get-ADUser {
	[CmdletBinding()]
	param (
		[string]
		$Filter,

		[Parameter(Mandatory = $true)]
		[string]
		$SearchBase,

		[string[]]
		$Properties
	)

	if (-not $script:_UserCache) {
		$script:_UserCache = @{}
		Import-PSFJson -Path "$PSScriptRoot\users.json" | Group-Object Path | ForEach-Object {
			$script:_UserCache[$_.Name] = $_.Group
		}
	}

	$script:_UserCache[$SearchBase]
}

function Get-ADGroup {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Identity,

		[switch]
		$NoWait
	)

	if (-not $script:_GroupCache) {
		$script:_GroupCache = Import-PSFJson -Path "$PSScriptRoot\groups.json" -AsHashtable
	}

	if (-not $NoWait) {
		$null = 1..5000 | Measure-Object -Sum
	}
	$script:_GroupCache[$Identity]
}

$null = Get-ADUser -SearchBase 'OU=Sales,OU=Users,OU=Contoso,DC=contoso,DC=com'
$null = Get-ADGroup -Identity 'abc'