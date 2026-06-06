# Failsafe
return

#----------------------------------------------------------------------------#
#                             Disk-Based Caching                             #
#----------------------------------------------------------------------------#

<#
Considerations:

- Disk IO
- Serialization / Format
- Concurrency
- Storage
- Sensitivity
- OS

Modi:

- Memory-Led
- File-Led
#>

<#
Serialization:
- CSV
- Json
- Clixml
...
- PSFClixml
#>
$files = Get-ChildItem -Path C:\Windows
$moreFiles = 1..100 | ForEach-Object { $files }
$moreFiles | Export-Clixml .\files.clixml
$moreFiles | Export-PSFClixml .\files.clidat
Get-ChildItem .\files.*
Import-PSFClixml .\files.clidat | Select-PSFObject -First 1
Import-PSFClixml .\files.clidat | Get-Member

#-> Next: One Big Data-Dump
code "$presentationRoot\C-02-SingleFile.ps1"

#-> What's with the hurry, Fred?
code "$presentationRoot\C-04-Mutex.ps1"