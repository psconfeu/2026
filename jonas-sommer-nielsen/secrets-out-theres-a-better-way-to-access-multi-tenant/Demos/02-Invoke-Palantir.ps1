<#
.SYNOPSIS
    Demo 2 — Invoke-Palantir across all of Middle-Earth.

.DESCRIPTION
    Same pattern as Demo 1, now looping over Shire, Rohan, Gondor.
    Highlights that adding a tenant = adding a row to a hashtable.
    Still no secrets, no certificates.

.NOTES
    Runbook  : Invoke-Palantir
    Account  : TheDarkTower (Mordor - Middle Earth)
    App Reg  : The One App  (<your-app-client-id>)
    FIC sub  : <your-mi-object-id>  (MI Object ID)
#>

param (
    [Parameter(Mandatory = $false)]
    [string] $OneAppClientId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'   # The One Ring app registration
)

$RemoteTenants = [ordered]@{
    'The Shire' = '11111111-1111-1111-1111-111111111111'
    'Rohan'     = '22222222-2222-2222-2222-222222222222'
    'Gondor'    = '33333333-3333-3333-3333-333333333333'
}

# ── 1. Single MI assertion — reused for every tenant ──────────────────────
$miAssertion = (Invoke-RestMethod `
    -Uri     $env:IDENTITY_ENDPOINT `
    -Method  POST `
    -Headers @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER } `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body    @{ resource = 'api://AzureADTokenExchange' }).access_token

Write-Output "🔮 The Palantír awakens. Gazing into Middle-Earth..."
Write-Output ""

foreach ($tenantName in $RemoteTenants.Keys) {
    $tenantId = $RemoteTenants[$tenantName]

    # ── 2. Exchange for a Graph token in this tenant ──────────────────────
    #      Fails with AADSTS700016 if The One App isn't consented here yet.
    try {
        $graphToken = (Invoke-RestMethod `
            -Uri    "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -Method POST `
            -ContentType 'application/x-www-form-urlencoded' `
            -Body @{
                grant_type            = 'client_credentials'
                client_id             = $OneAppClientId
                scope                 = 'https://graph.microsoft.com/.default'
                client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
                client_assertion      = $miAssertion
            }).access_token
    }
    catch {
        Write-Output "── $tenantName ──────────────────────────────────────"
        Write-Output "   ⛔ The App has no power here — admin consent not granted."
        Write-Output ""
        continue
    }

    # ── 3. Call Graph as "The One App" inside the remote tenant ──────────
    $users = (Invoke-RestMethod `
        -Uri     'https://graph.microsoft.com/v1.0/users?$select=displayName,userPrincipalName' `
        -Headers @{ Authorization = "Bearer $graphToken" }).value

    Write-Output "── $tenantName ($($users.Count) souls) ─────────────────────────"
    $users | ForEach-Object { Write-Output "   • $($_.displayName)  <$($_.userPrincipalName)>" }
    Write-Output ""
}

Write-Output "🔮 One App, three realms, zero secrets."
