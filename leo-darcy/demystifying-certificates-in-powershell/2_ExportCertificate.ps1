#Only Set Password Once
if ($null -eq $Password)
{
    $Password = Get-Credential -Message "Please Enter Certificate Password" -UserName "NOT USED"
}

#Get a specific Certificate
$Certificate = Get-Item -Path Cert:\CurrentUser\My\$($CustomCert.Thumbprint) -ErrorAction Stop

#Check that the certificate was found correctly
if ($Certificate.GetType().FullName -ne "System.Security.Cryptography.X509Certificates.X509Certificate2")
{
    throw "Thumbprint $($CustomCert.Thumbprint) not found"
}

#Export to a specific folder with the Friendly Name
$ExportPath = Join-Path -Path "Temp" -ChildPath "CertificateExport.pfx"

#PowerShell 5.1 only supports this with Legacy Crypto Providers as PowerShell is based on .Net 4.x ($PSVersionTable.CLRVersion.ToString())
#Broke in .Net 4.7 (PowerShell 5.1) https://www.pkisolutions.com/blog/accessing-and-using-certificate-private-keys-in-net-framework-net-core/
#Fixed in .Net 5+ (PowerShell 6+)

#Deprecated Approach to getting the Private Key - Still works
$PrivateKey = $Certificate.PrivateKey

#'Official' Approach to getting the Private Key based on Key Type
switch ($Certificate.PublicKey.Oid.Value)
{
    "1.2.840.113549.1.1.1" #RSA OID - Full list https://learn.microsoft.com/en-us/windows/win32/api/wincrypt/ns-wincrypt-crypt_algorithm_identifier
    {
        #NOTE: Having to call the Certificate Extension directly which is different from c# example code!
        $PrivateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
    }
    Default
    {
        throw "Script does not support Certificate Keys encrypted with $($Certificate.PublicKey.Oid.Value)"
    }
}

#Only attempt export if Private key exists and Export is allowed
if ($Certificate.HasPrivateKey -and $null -ne $PrivateKey -and $PrivateKey.Key.ExportPolicy -eq "AllowExport")
{
    $ExportArguments = @{
        "Cert"                  = $Certificate #Certificate Object, can be retrieved using Get-Item
        "FilePath"              = $ExportPath #Location to Save the file
        "Password"              = $Password.Password #Secure String to password protect the file
        "CryptoAlgorithmOption" = "AES256_SHA256" #Use the more secure encryption algorithm WS2019+
        "ChainOption"           = "BuildChain" #Include any applicable intermediate and root certificates
    }

    Export-PfxCertificate @ExportArguments
}
else
{
    throw "Certificate does not support Private Key Export"
}
