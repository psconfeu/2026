#Backend data storage of most certificates in PowerShell
[System.Security.Cryptography.X509Certificates.X509Certificate2]::new()

#Effectively and array of certificates but with some useful helper functions
$Collection = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()

#Grab a list of all certificates in the current user store
$Certs = Get-ChildItem Cert:\CurrentUser\My

# Add to Array
$Collection.AddRange($Certs)

#Count operates like and array
$Collection.Count

#Easy finding of certificates based on their actual attributes
#$Collection.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByTemplateName,"PSCWebServer")
$Collection.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByTimeExpired,[datetime]::Now, $false)
$Collection.Find([System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,"913d9201074638097ad1a7632538709eb6180c71", $false)

#Nice GUI for allowing user selection from a criteria
$Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::SelectFromCollection(
    $Collection,
    [System.Security.Cryptography.X509Certificates.X509SelectionFlag]::SingleSelection,
    "Choose a certificate",
    0 #IntPtr
)

$Cert