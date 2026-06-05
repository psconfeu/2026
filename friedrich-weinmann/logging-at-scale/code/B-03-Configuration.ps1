# failsafe
return

#----------------------------------------------------------------------------#
#                          Scenario: Configuration                           #
#----------------------------------------------------------------------------#

$resourcePath = "$presentationRoot\resources"

#-> Example
code "$resourcePath\by-configuration.ps1"
code "$resourcePath\config.psd1"
& "$resourcePath\by-configuration.ps1"

#-> More Advanced Config
code "$resourcePath\config-extended.psd1"

#-> Docs
# https://psframework.org/docs/PSFramework/Configuration/Persistence/persistence-manual-export-import#importing-import-psfconfig
# https://psframework.org/docs/PSFramework/Configuration/Schemata/schema-metajson

#-> Figuring out what to configure
Set-PSFLoggingProvider -Name eventlog -InstanceName conference -LogName PSFramework -Source Conference -Enabled $true
Get-PSFConfig '*.conference.*'

# Next: Scenario: Environment
code "$presentationRoot\B-04-Environment.ps1"