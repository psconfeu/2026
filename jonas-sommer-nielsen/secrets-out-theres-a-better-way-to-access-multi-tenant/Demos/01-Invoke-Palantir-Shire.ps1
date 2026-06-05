<#
.SYNOPSIS
    Demo 1 — The simplest possible secret-free cross-tenant call.

.DESCRIPTION
    Runs inside TheDarkTower Automation Account (Mordor).
    Uses the system-assigned Managed Identity, federated to "The One Ring"
    app registration, to read users from The Shire — no secrets, no certs.

    Three HTTP calls. That's it.

.NOTES
    Runbook  : Invoke-Palantir-Shire
    Account  : TheDarkTower (Mordor - Middle Earth)
    App Reg  : The One Ring  (2b3026ae-47d4-4e47-b04a-a0b0f8454ce2)
    FIC sub  : d0630ebd-b8f5-4a22-bb5e-c16507122088  (MI Object ID)
#>

$OneAppClientId = '2b3026ae-47d4-4e47-b04a-a0b0f8454ce2'
$ShireTenantId   = 'eafc0396-924f-4254-9a0d-26a46c372ded'

# ── 1. Ask Mordor's Identity endpoint for an assertion token ────────────────
#      Audience MUST be api://AzureADTokenExchange (not Graph, not ARM).
$miResponse = Invoke-RestMethod `
    -Uri     $env:IDENTITY_ENDPOINT `
    -Method  POST `
    -Headers @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER } `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body    @{ resource = 'api://AzureADTokenExchange' }

$miAssertion = $miResponse.access_token

# ── 2. Exchange that assertion for a Graph token in The Shire ──────────────
$tokenResponse = Invoke-RestMethod `
    -Uri    "https://login.microsoftonline.com/$ShireTenantId/oauth2/v2.0/token" `
    -Method POST `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body @{
        grant_type            = 'client_credentials'
        client_id             = $OneAppClientId
        scope                 = 'https://graph.microsoft.com/.default'
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion      = $miAssertion
    }

$shireGraphToken = $tokenResponse.access_token

# ── 3. Call Graph in The Shire as "The One App" ───────────────────────────
$users = Invoke-RestMethod `
    -Uri     'https://graph.microsoft.com/v1.0/users?$select=displayName,userPrincipalName' `
    -Headers @{ Authorization = "Bearer $shireGraphToken" }

"🔮 Palantír reveals the people of The Shire:"
$users.value | ForEach-Object { "   • $($_.displayName)  <$($_.userPrincipalName)>" }
