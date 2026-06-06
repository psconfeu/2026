# Failsafe
return

#----------------------------------------------------------------------------#
#                          Setting up this Madness                           #
#----------------------------------------------------------------------------#

#-> Configuration?
Get-PSFConfig -Module PSUtil

code "$presentationRoot\resources\zt.config-1.psd1"
Import-PSFConfig -Schema Psd1 -Path "$presentationRoot\resources\zt.config-1.psd1"
Get-PSFConfig -Module ZeroTrustAssessment

#-> Anywhere in the process:
Get-PSFConfigValue -FullName ZeroTrustAssessment.Graph.DisableCache

#-> Make it remember the setting:
Set-PSFConfig -Module ZeroTrustAssessment -Name 'Graph.DisableCache' -Value $true -PassThru | Register-PSFConfig

#-> Let's add logging
code "$presentationRoot\resources\zt.config-2.psd1"

# More Infos on PSFramework Configuration:
# https://psframework.org/docs/PSFramework/Configuration/overview

#-> Next: Restructuring for Clarity
code "$presentationRoot\A-07-Layout.ps1"