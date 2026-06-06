$NewUsers = Get-SystemUser -All -TimeTravel |
    Where-Object HasPersonalStorage -eq $false # Typical runtime: 10 seconds

# Create personal storage for all new users on the big server.
# Typical runtime: 1 hour
$NewUsers | New-PersonalStorage -Computer BigServer -TimeTravel

# Get data about personal storage usage. 
# Typical runtime: 6 hours
$PersonalStorageUsage = Get-PersonalStorage -Computer BigServer -TimeTravel |
    Select-Object User, Path, LastBackup, PercentUsed

# Export report about personal storage usage:
# Typical runtime: 10 minutes
$PersonalStorageUsage | Export-Excel .\PersonalStorageReport.xlsx
