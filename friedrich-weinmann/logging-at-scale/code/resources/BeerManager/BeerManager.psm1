function Resolve-Beer {
	[CmdletBinding()]
	param (
		[string]
		$User
	)

	Write-PSFMessage -Message 'Resolving preferred beer for {0}' -StringValues $User -Target $User -Tag Beer
	$beer = "Hofbräu","Becks","Augustiner" | Get-Random
	Write-PSFMessage -Message 'Preferred Beer of {0} is {1}' -StringValues $User, $beer -Target $User -Tag Beer

	[PSCustomObject]@{
		User = $User
		Beer = $beer
	}
}