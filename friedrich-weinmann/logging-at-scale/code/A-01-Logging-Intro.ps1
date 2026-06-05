# failsafe
return

#----------------------------------------------------------------------------# 
#                                  Logging                                   # 
#----------------------------------------------------------------------------# 

$resourcePath = "$presentationRoot\resources"

# Simple Logging
code "$resourcePath\logging-simple.ps1"
& "$resourcePath\logging-simple.ps1"
code "C:\Temp\demo\simple.log"

# Complex Logging
code "$resourcePath\logging-complex.ps1"
& "$resourcePath\logging-complex.ps1"
code "C:\Temp\demo\complex.csv"

# Next: PSFramework Logging Basics
code "$presentationRoot\A-02-PSF-Logging-Basics.ps1"