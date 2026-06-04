Import-Module ActiveDirectory -ErrorAction Stop

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Throw "Must Run these scripts as Admin"
}

#Delete all Generated Certificates
$TemplateOIDs = @(
    "1.3.6.1.4.1.311.21.8.7462531.7116760.8799632.203346.3145500.216.8249446.8961198"
    "1.3.6.1.4.1.311.21.8.7462531.7116760.8799632.203346.3145500.216.3654403.16266960"
    "1.3.6.1.4.1.311.21.8.7462531.7116760.8799632.203346.3145500.216.13939880.11087640"
)

foreach ($TemplateOid in $TemplateOIDs) {
    $TemplateSearch = "*$TemplateOid*"
    Get-ChildItem 'Cert:\LocalMachine\My' | Where-Object { $_.Extensions | Where-Object { ($_.Oid.FriendlyName -eq 'Certificate Template Information') -and ($_.Format(0) -like $TemplateSearch) } } | Remove-Item -Force
    Get-ChildItem 'Cert:\CurrentUser\My' | Where-Object { $_.Extensions | Where-Object { ($_.Oid.FriendlyName -eq 'Certificate Template Information') -and ($_.Format(0) -like $TemplateSearch) } } | Remove-Item -Force
}

$OldRequests = Get-ChildItem -Path cert:\LocalMachine\Request
foreach ($Request in $OldRequests) {
    $Request | Remove-Item -Force
}

#Ensure Temp folder exists in the local directory
if (-NOT (Test-Path -Path "Temp")) {
    New-Item -Path "Temp" -ItemType Directory
}

#Clear out all old temp files
Get-ChildItem -Path "Temp" | Remove-Item

#Get the domain distinguished name
$DomainDetails = Get-ADDomain -ErrorAction Stop

Get-ADObject -Identity "CN=PSCWorkstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$($DomainDetails.DistinguishedName)" -ErrorAction Stop

Set-ADObject -Identity "CN=PSCWorkstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$($DomainDetails.DistinguishedName)" -Replace @{
    DisplayName = "PSC Workstation"
}
