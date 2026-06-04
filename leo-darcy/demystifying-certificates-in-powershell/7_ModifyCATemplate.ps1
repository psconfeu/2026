#WARNING: This script makes unvalidated edits to your active directory configuration. 
#As such EXTREME care should be used prior to running anything based on this script

#Launch the Certificate Template Management GUI
certtmpl.msc

#Get the domain distinguished name
$DomainDetails = Get-ADDomain

#Locate all Certificate Templates using the known location and object type
$Templates = Get-ADObject -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$($DomainDetails.DistinguishedName)" `
                        -LDAPFilter "(objectClass=pKICertificateTemplate)" -Properties *

$Templates | Format-Table -Property Name, DisplayName, pKIExtendedKeyUsage

#Locate a specific template to modify
$TemplateToModify = Get-ADObject -Identity "CN=PSCWorkstation,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$($DomainDetails.DistinguishedName)" 

#Update the display name directly in AD
Set-ADObject -Identity $TemplateToModify.DistinguishedName -Replace @{
    DisplayName = "PSC Workstation Modified"
}

#Launch the Certificate Template Management GUI
certtmpl.msc