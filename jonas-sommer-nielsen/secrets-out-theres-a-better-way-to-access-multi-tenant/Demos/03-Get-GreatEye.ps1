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
    App Reg  : The One Ring  (2b3026ae-47d4-4e47-b04a-a0b0f8454ce2)
    FIC sub  : d0630ebd-b8f5-4a22-bb5e-c16507122088  (MI Object ID)
#>

param (
    [Parameter(Mandatory = $false)]
    [string] $OneRingClientId = '2b3026ae-47d4-4e47-b04a-a0b0f8454ce2'
)

$RemoteTenants = [ordered]@{
    'The Shire' = 'eafc0396-924f-4254-9a0d-26a46c372ded'
    'Rohan'     = '5af80872-b2e7-4cc4-807a-498754230280'
    'Gondor'    = '3e1e38ee-0408-49f7-b037-2a23073678bf'
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
