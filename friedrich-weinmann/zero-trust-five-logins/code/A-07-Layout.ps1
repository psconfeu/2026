# Failsafe
return

#----------------------------------------------------------------------------#
#          A Small, Minor Update. Nothing Could Possibly Go Wrong!           #
#----------------------------------------------------------------------------#

#-> Tour the module

# Adding Tests
#---------------


<#
Desired Pattern:
- One File per Function
- No Duplicate Command Names

Why?
#>

# Splitting Functions in a File
#---------------------------------

code "$presentationRoot\resources\messy-functions.ps1"
New-Item -Path "$presentationRoot\resources\functions" -ItemType Directory
Split-PSMDScriptFile -File "$presentationRoot\resources\messy-functions.ps1" -Path "$presentationRoot\resources\functions"

<#
Module: PSModuleDevelopment
https://psframework.org
#>

# Return of the AST :scream:
#-----------------------------

code "$presentationRoot\resources\Get-AstFunctionDefinition.ps1"
. "$presentationRoot\resources\Get-AstFunctionDefinition.ps1"
Get-AstFunctionDefinition -Path "$presentationRoot\resources\messy-functions.ps1" | ft

#-> One File Per Function
code "$presentationRoot\resources\OneCommandPerFile.Tests.ps1"

#-> No Command Duplicates
code "$presentationRoot\resources\UniqueCommands.Tests.ps1"

#-> Next: User Experience vNext
code "$presentationRoot\A-08-TabExpansion.ps1"