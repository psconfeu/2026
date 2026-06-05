<#
.SYNOPSIS
    Demo 3 — Get-GreatEye: Sauron's eye sweeps the realms for subscriptions.

.DESCRIPTION
    Same federated identity pattern as Demos 1 & 2 — but the only thing that
    changes is the SCOPE: instead of Graph, we ask for an ARM token, and
    instead of /users we call /subscriptions in each remote tenant.

    Message of the demo: the federation pattern is API-agnostic. Graph today,
    ARM tomorrow, anything OAuth-protected the day after.

.PREREQUISITES
    "The One Ring" service principal must have at least the **Reader** role
    on each subscription you want to see (assigned per remote subscription).

.NOTES
    Runbook  : Get-GreatEye
    Account  : TheDarkTower (Mordor - Middle Earth)
    App Reg  : The One Ring  (<your-app-client-id>)
    FIC sub  : <your-mi-object-id>  (MI Object ID)
#>

param (
    [Parameter(Mandatory = $false)]
    [string] $OneRingClientId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'   # The One Ring app registration
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

Write-Output "👁️  The Great Eye opens. Searching the realms..."
Write-Output ""

foreach ($tenantName in $RemoteTenants.Keys) {
    $tenantId = $RemoteTenants[$tenantName]

    # ── 2. Exchange for an ARM token (note the scope change!) ─────────────
    #      Fails with AADSTS7000229 if The One Ring has no SP in this tenant.
    try {
        $armToken = (Invoke-RestMethod `
            -Uri    "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -Method POST `
            -ContentType 'application/x-www-form-urlencoded' `
            -Body @{
                grant_type            = 'client_credentials'
                client_id             = $OneRingClientId
                scope                 = 'https://management.azure.com/.default'
                client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
                client_assertion      = $miAssertion
            }).access_token
    }
    catch {
        Write-Output "── $tenantName ─────────────────────────────────────"
        Write-Output "   ⛔ The Ring has no power here — no service principal in this tenant."
        Write-Output ""
        continue
    }

    # ── 3. List subscriptions visible to The One Ring in this tenant ──────
    $subs = (Invoke-RestMethod `
        -Uri     'https://management.azure.com/subscriptions?api-version=2022-12-01' `
        -Headers @{ Authorization = "Bearer $armToken" }).value

    Write-Output "── $tenantName ─────────────────────────────────────"
    if ($subs.Count -eq 0) {
        Write-Output "   (no subscriptions visible — assign Reader to The One Ring)"
    }
    else {
        $subs | ForEach-Object {
            Write-Output "   🗺️  $($_.displayName.PadRight(28)) $($_.subscriptionId)  [$($_.state)]"
        }
    }
    Write-Output ""
}

Write-Output "👁️  The Eye sees all. Same pattern, different audience."
