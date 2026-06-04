#Provision an automatically approved certificate to the local machine store
Get-Certificate -Template "PSCWebServer" `
                -CertStoreLocation Cert:\LocalMachine\My `
                -DnsName "www.test.leo.psc" 

#Note that the DNS Name was ignored but the certificate issued anyway
certlm.msc

#Start the Request for a custom certificate that needs approval to limit ESC1 abuse
$CertificateRequest = Get-Certificate -Template "PSCCustomWebServer" `
                                    -SubjectName "CN=myapp.leo.psc" `
                                    -CertStoreLocation Cert:\LocalMachine\My

$CertificateRequest

#Review the storage location for these requests
Get-ChildItem -Path Cert:\LocalMachine\REQUEST

#Approve the Request Manually
certsrv.msc

#Attempt to retrieve the request
Get-Certificate -Request $CertificateRequest.Request

#Review certificate has been issued with custom subject
certlm.msc
