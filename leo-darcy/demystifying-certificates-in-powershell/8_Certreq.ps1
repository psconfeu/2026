
#Create a custom CSR Manually
$RequestWithTemplate = @"
[NewRequest]
Subject = "CN=server.leo.psc"
FriendlyName = "Certificate Request"
KeyLength = 2048
[RequestAttributes]
CertificateTemplate=PSCWebServer
"@

$ADCSServerName = "PSC-ADCS-01.Leo.PSC\Leo-PSC-ADCS-01-CA"

#Create storage locations
$RequestDetailsPath = Join-Path -Path "Temp" -ChildPath "Cert Request.inf"
$CSRPath = Join-Path -Path "Temp" -ChildPath "Cert Request.csr"
$CERPath = Join-Path -Path "Temp" -ChildPath "PublicCert.cer"

#Save request into a file
$RequestWithTemplate | Out-File -FilePath $RequestDetailsPath

#https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1
#-new turns the request details into a valid CSR
certreq.exe -new -machine -f $RequestDetailsPath $CSRPath
#Review the new configuration
certutil.exe -dump $CSRPath
#Submit the request and return the public certificate that relates to the request. Forcing the use of the Machine Context as this is a Web Server Certificate
certreq.exe -submit -config $ADCSServerName -adminforcemachine -f $CSRPath $CERPath
#Retreive the certificate and store in the machine store
certreq.exe -accept -config $ADCSServerName -machine $CERPath

certlm.msc #View the Certificate Store with the new certificate

#Simulate a request from a third party piece of software that generates a CSR without a template associated with it
$RequestNoTemplate = @"
[NewRequest]
FriendlyName = "Certificate Request Without Template"
KeyLength = 2048
"@

#Save the request to the file
$RequestNoTemplate | Out-File -FilePath $RequestDetailsPath

#Generate the CSR
certreq.exe -new -machine -f $RequestDetailsPath $CSRPath
#Add in the Template Information to the CSR as it is being sent to the CA
certreq -submit -attrib "CertificateTemplate:PSCWebServer" -config $ADCSServerName -adminforcemachine -f $CSRPath $CERPath 
#Retrieve the approved Certificate request
certreq.exe -accept -config $ADCSServerName -machine $CERPath
certlm.msc #View the Certificate Store with the new certificate