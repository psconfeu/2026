#Only Set Password Once
if ($null -eq $Password)
{
    $Password = Get-Credential -Message "Please Enter Certificate Password" -UserName "NOT USED"
}

$ImportArguments = @{
    "FilePath"          = '.\Temp\CertificateExport.pfx'
    "CertStoreLocation" = "Cert:\CurrentUser\My"
    "Password"          = $Password.Password 
    "ProtectPrivateKey" = "VSM" #Protect the key with Virtualization Based Security (No Export)
}

Import-PfxCertificate @ImportArguments
