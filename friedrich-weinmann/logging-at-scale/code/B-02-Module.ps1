# failsafe
return

#----------------------------------------------------------------------------#
#                              Scenario: Module                              #
#----------------------------------------------------------------------------#

$resourcePath = "$presentationRoot\resources"

# Not Your Job Anymore
#-> Module with Classic Logging
code "$resourcePath\BeerManagerOld\BeerManagerOld.psm1"

#-> Module with PSFramework Logging
code "$resourcePath\BeerManager\BeerManager.psm1"

# Support Package
New-PSFSupportPackage -Path .

# Next: Scenario: Configuration
code "$presentationRoot\B-03-Configuration.ps1"