# failsafe
return

#----------------------------------------------------------------------------#
#                              Scenario: Script                              #
#----------------------------------------------------------------------------#

$resourcePath = "$presentationRoot\resources"

# All Inclusive
code "$resourcePath\script-logging-1.ps1"
& "$resourcePath\script-logging-1.ps1"
code "C:\Temp\demo\BeerTask-$(Get-Date -Format 'yyyy-MM-dd').csv"

# Selective
code "$resourcePath\script-logging-2.ps1"
& "$resourcePath\script-logging-2.ps1"
code "C:\Temp\demo\BeerTask2-$(Get-Date -Format 'yyyy-MM-dd').csv"

# Next: Scenario: Modules
code "$presentationRoot\B-02-Module.ps1"