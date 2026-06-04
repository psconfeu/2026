$InitialCert = New-SelfSignedCertificate -FriendlyName "I'm a TeaPot" `
        -Subject "CN=server1.leo.home" `
        -CertStoreLocation Cert:\CurrentUser\My
$InitialCert

#Launch Current User Certificate Store GUI
certmgr.msc
#Launch Local Machine Certificate Store GUI (Requires Admin)
certlm.msc

#PS Drives
Get-PSDrive

Get-ChildItem -Path cert:\

#List all User Certificates
Get-ChildItem -Path Cert:\CurrentUser\My | Format-Table Thumbprint, Subject, FriendlyName

#Get all the details about a specific certificate
Get-Item -Path Cert:\CurrentUser\My\$($InitialCert.Thumbprint) | Format-List -Property *

#More advanced certificate creation
$CertificateArguments = @{
    "FriendlyName"      = "I'm a TeaPot" #Value to help finding it in the Certificate store
    "Subject"           = "CN=server2.leo.home" #Primary hostname for the certificate to be validated against
    "CertStoreLocation" = "Cert:\CurrentUser\My" #Location to store the certificate
    "KeyLength"         = 4096 #Size of the RSA algorithm to use (2048, 3072 and 4096 are common)
    "DnsName"           = @("myapp.leo.home", "myapp2.leo.home") #Additional hostnames accepted by the certificate
    "NotBefore"         = (Get-Date).AddMinutes(-5) #Start 5 minutes before the current time
    "NotAfter"          = (Get-Date).AddMonths(2) #Last for 2 months
    "KeyExportPolicy"   = "ExportableEncrypted"
    "KeyAlgorithm"      = "RSA"
    "HashAlgorithm"     = "SHA256"
    "TextExtension"     = "2.5.29.37={text}1.3.6.1.5.5.7.3.1" #Server Authentication
    "Provider"          = "Microsoft Software Key Storage Provider" #https://michaelwaterman.nl/2023/10/13/pki-part-4-understanding-cryptographic-providers/
}

#Generate a more interesting certificate
$CustomCert = New-SelfSignedCertificate @CertificateArguments 

$CustomCert | Format-List -Property *