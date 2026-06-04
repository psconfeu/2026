#Delete all self signed certificates
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object Subject -Like "*.leo.home" | Remove-Item
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object Subject -Like "*.mydomain.co.uk" | Remove-Item

#Ensure Temp folder exists in the local directory
if (-NOT (Test-Path -Path "Temp"))
{
    New-Item -Path "Temp" -ItemType Directory
}

#Clear out all old exported certificates
Get-ChildItem -Path "Temp" | Remove-Item

#Only Set Password Once
if ($null -eq $Password)
{
    $Password = Get-Credential -Message "Please Enter Certificate Password" -UserName "NOT USED"
}

$SubscriptionID = "<GUID>"

Write-Output "Logging into Azure"

#Call the authentication in an external browser so that 1Password kicks in and it pops up over the top of VS Code
#https://github.com/AzureAD/microsoft-authentication-library-for-dotnet/issues/4887
pwsh -noprofile -command Connect-AzAccount -Subscription $SubscriptionID

Connect-AzAccount -Subscription $SubscriptionID

$recordDetails = Get-AzDnsRecordSet -Name "_acme-challenge.psconf" -RecordType TXT -ZoneName "mydomain.co.uk" -ResourceGroupName "DNS"
