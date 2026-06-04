#Install-Module -Name Posh-ACME -Scope CurrentUser

Import-Module -Name Posh-ACME -ErrorAction Stop
Import-Module -Name Az.Accounts -ErrorAction Stop

$CertificateName = "psconfeu.mydomain.co.uk"

#Fails due to incorrect DNS
New-PACertificate -Domain $CertificateName -AcceptTOS -Force -Verbose

$token = Get-AzAccessToken

#Request a new certificate, if needed log into Azure and update the DNS challenge to prove ownership of the domain
$ACMECert = New-PACertificate -Domain $CertificateName -AcceptTOS -Plugin Azure -PluginArgs @{
    AZSubscriptionId    = $SubscriptionID
    AZAccessTokenSecure = $token.Token
} -Force -FriendlyName "ACME Request" -Verbose -Install:$false -DnsSleep 5 #Disable install to avoid needing to run as Admin

#Install the certificate in the local user store
Install-PACertificate -PACertificate $ACMECert -StoreLocation CurrentUser -StoreName My -NotExportable

#Launch Viewer
certmgr.msc