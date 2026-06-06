# Failsafe
return

#----------------------------------------------------------------------------#
#                                 Hashtables                                 #
#----------------------------------------------------------------------------#

# Why we cache ...
#-------------------

function Get-GroupMembershipReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$SearchBase
	)

	$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties memberOf
	foreach ($user in $users) {
		foreach ($groupDN in $user.memberOf) {
			$group = Get-ADGroup -Identity $groupDN

			[PSCustomObject]@{
				UserSam  = $user.SamAccountName
				UserDN   = $user.DistinguishedName
				GroupSam = $group.SamAccountName
				GroupDN  = $group.DistinguishedName
			}
		}
	}
}
$memberships = Get-GroupMembershipReport -SearchBase 'OU=Engineering,OU=Users,OU=Contoso,DC=contoso,DC=com'
$memberships.Count
$memberships[0]


# Let's cache
#--------------

function Get-GroupMembershipReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$SearchBase
	)

	# Create Empty Cache
	$groupCache = @{}

	$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties memberOf
	foreach ($user in $users) {
		foreach ($groupDN in $user.memberOf) {
			# If the group hasn't been retrieved yet ...
			if (-not $groupCache[$groupDN]) {
				# ... retrieve group from AD and add to cache
				$groupCache[$groupDN] = Get-ADGroup -Identity $groupDN
			}

			[PSCustomObject]@{
				UserSam  = $user.SamAccountName
				UserDN   = $user.DistinguishedName
				GroupSam = $groupCache[$groupDN].SamAccountName
				GroupDN  = $groupCache[$groupDN].DistinguishedName
			}
		}
	}
}
$memberships = Get-GroupMembershipReport -SearchBase 'OU=Engineering,OU=Users,OU=Contoso,DC=contoso,DC=com'
$memberships[0]
$memberships.Count


# New Situation, new Trouble
#-----------------------------

function Get-DepartmentReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Departments
	)

	foreach ($department in $Departments) {
		Get-GroupMembershipReport -SearchBase "OU=$department,OU=Users,OU=Contoso,DC=contoso,DC=com"
	}
}
$memberships = Get-DepartmentReport -Departments Engineering, Sales, HR


# Portable Cache
#-----------------

# A Simple Move ...
function Get-GroupMembershipReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$SearchBase,
		$GroupCache = @{}
	)


	$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties memberOf
	foreach ($user in $users) {
		foreach ($groupDN in $user.memberOf) {
			# If the group hasn't been retrieved yet ...
			if (-not $GroupCache[$groupDN]) {
				# ... retrieve group from AD and add to cache
				$GroupCache[$groupDN] = Get-ADGroup -Identity $groupDN
			}

			[PSCustomObject]@{
				UserSam  = $user.SamAccountName
				UserDN   = $user.DistinguishedName
				GroupSam = $GroupCache[$groupDN].SamAccountName
				GroupDN  = $GroupCache[$groupDN].DistinguishedName
			}
		}
	}
}

function Get-DepartmentReport {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Departments
	)

	$cache = @{}
	foreach ($department in $Departments) {
		Get-GroupMembershipReport -SearchBase "OU=$department,OU=Users,OU=Contoso,DC=contoso,DC=com" -GroupCache $cache
	}
}
$memberships = Get-DepartmentReport -Departments Engineering, Sales, HR

#-> Next up: Let's make this more complicated
code "$presentationRoot\A-02-Considerations.ps1"