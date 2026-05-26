# Microsoft Graph mit PowerShell 101

***
**Inhalt**
1. [Anforderungen](#anforderungen)
   - [Hart](#harte-anforderungen)
   - [Soft](#anforderungen-um-bis-zum-bitteren-ende-mitzumachen)
1. [Start](#deine-reise-startet-hier)
   1. [Intro](#intro)
   1. [Goal](#zielsetzung)
   1. [Konfiguration der Umgebung](#vorbedingungen)
   1. [App Registrations und Enterprise Applications](#app-registrations-und-enterprise-applications)
   1. [Scopes und Roles](#scopes-und-roles)
   1. [Consent](#consent)
   1. [Streng geheim](#streng-geheim)
   1. [OData Query Parameter](#odata-query-parameter)
   1. [So wird ein Schuh draus](#so-wird-ein-schuh-draus)
   1. [Abschließende Bemerkungen](#abschließende-bemerkungen)
***

# Anforderungen

## Harte Anforderungen

Diese Bedingungen **müssen** vorab erfüllt sein, um dem kleinen Workshop zu folgen. Ich empfehle, einen
eigenen Entra-Tenant anzulegen, falls du das noch nicht gemacht hat. Entra ist grundsätzlich kostenfrei, somit
auch das Testen vieler Graph-Operationen.

- Linux/Windows
- PowerShell 7
- Entra-Tenant (kostenfrei): https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant
  - Kreditkarte notwendig, aber wird nicht belastet! Azure ist schließlich nicht AWS :wink:
  - Alternativ kann eine stark eingeschränkte Identität aus dem Trainer-Tenant genutzt werden, damit macht es aber weniger Spaß.

## Anforderungen um bis zum bitteren Ende mitzumachen

Um bis zum Ende alles mitmachen zu können, solltet ihr noch über einen GitHub Account verfügen.

# Deine Reise startet hier

## Intro

Microsoft Graph ist ideal, um die diversen nervigen Aufgaben in Entra ID
wegzuautomatisieren. Unser Hauptziel für diesen Follow-Along ist, eine Graph-App
für genau diese Zwecke zu erstellen.

Wir werden uns ganz kurz mit Graph X-Ray und dem Graph-Explorer beschäftigen, bevor
wir uns knietief in den Doku-Sumpf begeben, und die Bereiche herausfischen, die für
uns relevant sind.

Eine Warnung vorab: Wir werden uns vor Allem in der bequemen Umarmung von PowerShell
wiederfinden. Die diversen Administrations-Portale sollten immer nur das letzte Mittel sein,
um zu administrieren...

## Zielsetzung

- Eine App erstellen die
   - Von einem Help Desk genutzt werden kann, um interaktiv Authentifizierungs-Methoden zurückzusetzen (Trainer Tenant: Nur Windows Hello)
   - Die in einer Pipeline oder einem Automation Runbook genutzt werden kann, um nicht-interaktiv abgelaufene Secrets von Entra Apps zu reporten

## Vorbedingungen

Um mit Graph zu arbeiten, braucht ihr beileibe nicht die fast 1GiB autogenerierten Code von `Microsoft.Graph` (Microsoft.Graph 1GiB, Microsoft.Entra 0.3GiB).
In dieser Session nutzen wir das schlanke Modul EntraAuth (0.0001GiB...). Damit starten wir dann auch:

`Install-Module Az.Accounts, EntraAuth -Scope CurrentUser`

Um die Arbeit etwas angenehmer zu machen, installieren wir auch gleich Az.Accounts. So können wir unsere Azure-Credentials
nutzen, um uns an Graph anzumelden.

Das ist zwar strenggenommen nicht notwendig, um zu arbeiten, erleichtert jedoch das Erstellen unserer App Registration ungemein.

## App Registrations und Enterprise Applications

Um überhaupt in die Lage versetzt zu werden, sich mit einem bestimmten Satz an Berechtigungen interaktiv
oder nicht-interaktiv anzumelden, benötigen wir immer eine Entra-Applikation. Muss die in deinem Tenant liegen? Mal sehen:

- Application
   - Beschreibt, wie du dich verbindest
   - Beschreibt, welche Berechtigungen verfügbar sein sollen
   - Beschreibt die von der App bereitgestellten Rollen und Scopes
   - Beinhaltet Credentials, die zur Verbindung eventuell notwendig sind
   - Lebt im entfernen Tenant (!), der ein Produkt bereitstellt, z.B. eine SaaS-Lösung
- Enterprise Application (Service Principal)
  - Beschreibt, wer sich verbinden darf
  - Beschreibt, ob und wie die Application im Heim-Tenant verfügbar sein soll
  - Lebt im Heim-Tenant und konsumiert Ressourcen des entfernten Tenants
  - Werden erstellt für alle System- und User-Assigned Managed Identities

Genug davon, los geht's!

1. Die genutzte API-Ressource heißt [application](https://learn.microsoft.com/en-us/graph/api/resources/applications-api-overview?view=graph-rest-1.0)
1. Um eine Applikation zu erstellen, nutzen wir welche Methode?
   <details>
   <summary>Hilfe!</summary>

   [Create](https://learn.microsoft.com/en-us/graph/api/application-post-applications?view=graph-rest-1.0&tabs=http)
   </details>
1. Gegenüber Azure authentifizieren mit `Connect-AzAccount`
1. Gegenüber Graph authentifizieren mit `Connect-EntraService -Service Graph -AsAzAccount`
1. Nun geht es darum, den Request-Body zu bauen. Die App soll den Anzeigenamen "PSConf Anniversary: Graph 101" erhalten.
   <details>
   <summary>Hinweis</summary>

   Schau dir mal die API-Resource <https://learn.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0> an.
   Ähnlich zu PowerShell-Objekten haben Graph-Ressourcen Eigenschaften und Methoden.

   Unser Request-Body sieht daher so aus:
   ```powershell
    $body = @{
        displayName = "PSConf Anniversary: Graph 101"
    }
   ```
   </details>
1. Um sich an einer Graph-App interaktiv anmelden zu können, müssen wir noch die Authentifizierungsmethode konfigurieren.
   Unsere Applikation verhält sich hier wie ein "Public Client", und wird entsprechend konfiguriert.
   <details>
   <summary>Hinweis</summary>

   Unser Request-Body wird erweitert zu:
   ```powershell
    $body = @{
    displayName            = "PSConf Anniversary: Graph 101"
    publicClient           = @{
        redirectUris = @(
            'http://localhost'
        )
      }
    }
   ```
   </details>
1. Mit dieser Konfiguration können wir uns im Browser anmelden. Um auch Device Code Anmeldungen zu ermöglichen, kann die Property `isFallbackPublicClient = $true` konfiguriert werden.
1. Um die Applikation bereitzustellen, nutzen wir `Invoke-EntraRequest` - aber wie? Und mit welcher Methode?
   <details>
   <summary>Hinweis</summary>

   Der Parameter `Path` erwartet einen API path relativ zu der API-Basis-Url.
   Das wäre in unserem Fall `application`.
   Liest man ein wenig in der Doku oder rät, kommt man auf die Methode `POST` - nicht ungewöhnlich bei REST APIs.  

   Der vollständige Call lautet also `$app = Invoke-EntraRequest -Path applications -Method Post -Body $body -ContentType application/json`
   </details>
1. Glückwunsch! Gar nicht so schwer, oder? Notier' dir die AppId, wir brauchen sie später noch zwei, drei Mal: `$app.appId`

>Hinweis: Da wir noch keine Rollen und Scopes eingetragen haben, kann sich an der App noch nicht angemeldet werden.

## Scopes und Roles

Um die App für irgendwelche Automationszwecke zu nutzen, müssen wir die Rollen und Scopes hinzufügen, die wir benötigen. Warum
macht man diese Trennung?

OAuth2 Permission Scopes beschreiben die delegierten Berechtigungen, die interaktiv angemeldeten Benutzern zu Verfügung gestellt werden.
Rollen beschreiben Applikations-Rollen die nicht-interaktiven Nutzern zu Verfügung steht, beispielsweise App Registrations.

Also, wo fängt man an, wenn man nach möglichen Rollen sucht? Tja, die Hersteller-Quelle ist in diesem Fall am Besten geeignet: <https://learn.microsoft.com/en-us/graph/permissions-reference>

So, where do we get started while looking for resources? Well, the authoritative source
is always best: <https://learn.microsoft.com/en-us/graph/permissions-reference>. Merrill Fernando, Principal Product Manager für Entra,
stellt ebenfalls einen super Überblick bereit: <https://graphpermissions.merill.net/permission/>

Auch ein guter Startpunkt, um von ClickOps wegzukommen, ist die Browser-Extension [Graph X-Ray](https://graphxray.merill.net/). Erinnert
ihr euch noch an das Feature, Scripts zu exportieren aus Tools wie z.B. SCVMM? Graph X-Ray gibt euch dieses Feature für Entra!

Ebenfalls hilfreich ist der [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer). Anhand von Beispieldaten
oder aber dem eigenen Tenant können hier einzelne Calls über eine UI gestartet werden.

Aber: Zu viel UI ist ungesund, also husch husch, zurück in die CLI.

1. Schauen wir uns die App an, die wir eben registriert haben, fällt die Eigenschaft `requiredResourceAccess` auf. Schauen wir
   in die API-Doku [der Eigenschaft](https://learn.microsoft.com/en-us/graph/api/resources/requiredresourceaccess?view=graph-rest-1.0) und
   die der [resourceAccess-Collection](https://learn.microsoft.com/en-us/graph/api/resources/resourceaccess?view=graph-rest-1.0), sehen wir,
   dass wir eine Object-ID benötigen. Aber die welcher Ressource?

   Die Ressource bezieht sich hier auf das Service Principal im Heim-Tenant. Während MS Graph immer die Client ID `00000003-0000-0000-c000-000000000000` hat,
   ist das Service Principal pro Tenant einzigartig.
1. Wir suchen zunächst die ResourceId, also: Das Service Principal in unserem Tenant. da wir die AppId kennen, können wir die
   servicePrincipal API fragen:

   ```powershell
   $graphAppId = '00000003-0000-0000-c000-000000000000'
   $graphServicePrincipal = Invoke-EntraRequest -Path "servicePrincipals(appId='$graphAppId')"
   ```
1. Um PowerShell nie verlassen zu müssen, können wir nun die Scopes und Rollen in den Eigenschaften `oauth2PermissionScopes` und `appRoles` finden!
   
   ```powershell
   $graphServicePrincipal.oAuth2PermissionScopes
   $graphServicePrincipal.appRoles
   ```
1. Unsere delegierte Berechtigung hatte was mit Hello und Authentication zu tun. Zeit, danach zu suchen!
   
   ```powershell
   # Delegated - Das bedeutet: Scope!
   $graphServicePrincipal.oAuth2PermissionScopes | Where value -match Hello
   ```
1. Der vorherige Befehl sollte 4 Scopes ausgeben. In unserem Help Desk Szenario klingt `UserAuthMethod-WindowsHello.ReadWrite.All` recht passend. Hier
   erkennt ihr übrigens, dass die ID der Berechtigung der ID in der Graph-Rechtedoku entspricht.
   So können wir unseren ersten Eintrag in der requiredResourceAccess-Liste anlegen!
   
   ```powershell
   # Delegated - Meaning: Scope!
   $delegate = $graphServicePrincipal.oAuth2PermissionScopes | Where value -eq UserAuthMethod-WindowsHello.ReadWrite.All
   $body = @{
      displayName            = "PSConf Anniversary: Graph 101"
      publicClient           = @{
         redirectUris = @(
               'http://localhost'
         )
      }
      requiredResourceAccess = @(@{
         resourceAppId  = $graphServicePrincipal.appId
         resourceAccess = @(
               @{
                  id   = $delegate.id
                  type = "Scope"
               }
         )
      })
   }
   ```
1. Wir gehen ähnlich vor, um die App-Rolle zu finden. Die App soll abgelaufene Secrets exportieren, daher nehmen wir `Application.Read.All`.

   ```powershell
   $role = $graphServicePrincipal.appRoles | Where value -eq Application.Read.All
   $body.requiredResourceAccess[0].resourceAccess += @{
      id   = $role.id
      type = "Role"
   }
   ```
1. Eure Payload sollte im Groben so aussehen:

   ```json
   {.
   "requiredResourceAccess": [
      {
         "resourceAccess": [
         {
            "type": "Scope",
            "id": "13eae17d-aaa4-47b8-aaee-0eb33c6e2450"
         },
         {
            "type": "Role",
            "id": "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
         }
         ],
         "resourceAppId": "00000003-0000-0000-c000-000000000000"
      }
   ],
   "publicClient": {
      "redirectUris": [
         "http://localhost"
      ]
   },
   "displayName": "PSConf Anniversary: Graph 101"
   }
   ```
1. Wenn das erledigt ist, können wir mit einem `PATCH` und der AppId bzw. Object-ID die Applikation aktualisieren:
   
   `Invoke-EntraRequest -Method Patch -Path applications/$graph`
1. Schick' noch einen GET hinterher, um die zu verifizieren, dass die Rechte korrekt eingetragen wurden. Alternativ siehst du diese Info im Azure Portal.
1. Glückwunsch! Wir nähern uns in riesigen Schritten dem Ziel, alles zu automatisieren.

Als nächstes kommt: Consent!

## Consent

Consent, also die Genehmigung von Rechte-Wünschen, ist in Entra ID zweigeteilt. Consent beschreibt den Zustand eurer Applikations-Rechte: Wurde
seitens eines Users oder Admins genehmigt, dass eure App die angeforderten Rollen auch nutzen kann?

Wenn kein administrativer Consent notwendig ist, wie zum Beispiel bei `User.Read`, kann der User in der Regel selbst die Zustimmung geben. Das hängt
auch von euren Tenant-Einstellungen ab. Für andere, weitreichende Berechtigungen, kann Admin-Consent nötig sein. So auch für unsere delegierte
Berechtigung `UserAuthMethod-WindowsHello.ReadWrite.All`.

In unserem Fall wird für beide Berechtigungen ein Admin-Consent nötig.

1. Wir fangen mit dem simplen Teil an, der App-Rolle. In der [Doku](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignments?view=graph-rest-1.0&tabs=http) finden
   wir heraus, dass wir drei Infos brauchen, die resource id, principal ID und app role id.
   
   Die Resource ID ist die ID des Graph **Service Principal**, da wir den Zugriff in unserem Heim-Tenant brauchen.
   Die principal id ist die Object id des Service Principals unserer Applikation.
   Die app role id haben wir im vorherigen Schritt schon geholt.

1. Mit diesen Infos bewaffnet, bereiten wir den ersten Request vor:

   ```powershell
   $appServicePrincipal = Invoke-EntraRequest -Path "servicePrincipals(appid='cdc0925b-d7eb-49c8-bc92-980dc5da44b2')"
   $graphApp = '00000003-0000-0000-c000-000000000000'
   $graphServicePrincipal = Invoke-EntraRequest -Path "servicePrincipals(appId='$graphApp')"
   $role = $graphServicePrincipal.appRoles | Where value -eq Application.Read.All
   $roleAssignment = @{
      principalId = $appServicePrincipal.id
      resourceId  = $graphServicePrincipal.id
      appRoleId   = $role.id
   }
   ```
1. Da wir etwas neues anlegen, starten wir einen POST:

   `Invoke-EntraRequest -Method Post -Path servicePrincipals/$($appServicePrincipal.id)/appRoleAssignments -Body $roleAssignment -ContentType application/json`

1. Ausgezeichnet. Kommen wir nun zum zweiten Punkt: Delegierten Consent erteilen! Nach einer Suche nach dem Stichwort `grants`
   kommen wir irgendwann zu [der Doku](https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-post?view=graph-rest-1.0&tabs=http).

   Der Consent-Type `AllPrincipals` ist recht selbsterklärend: Consent für alle User im Tenant! Wählt ihr den Typ `Principal`, müsstet
   ihr eine Object ID angeben.

   Der Scope ist dieses Mal eine mit Leerzeichen getrennte Liste von String. Ooooh Junge! Die Entwickler dieser speziellen Schnittstelle mochten scheinbar keine Arrays.
   
   ```powershell
   $delegate = $graphServicePrincipal.oAuth2PermissionScopes | Where value -eq UserAuthMethod-WindowsHello.ReadWrite.All
   $oauth2PermissionGrant = @{
      resourceId  = $graphServicePrincipal.id
      consentType = 'AllPrincipals'
      clientId    = $appServicePrincipal.id
      scope       = $delegate.value -join ' ' # Oder ihr vertraut dem $OFS
   }
   ```
1. Dieser Request geht an... den oauth2PermissionGrants Endpunkt! Auch wenn man eigentlich annehmen würde, dass ein solcher Endpunkt
   eher auf ein Service Principal gescoped wäre, gilt dieser für den gesamten Tenant.

   `Invoke-EntraRequest -Method Post -Path oauth2PermissionGrants -Body $oauth2PermissionGrant -ContentType application/json`
1. Gute Arbeit! Jetzt können wir uns **endlich** anmelden! Versuch es mal mit `Connect-EntraService`!
   <details>
   <summary>Hinweis</summary>

   `Connect-EntraService -Service Graph -ClientID $appServicePrincipal.appId -TenantID (Get-AzContext).Tenant.Id`
   </details>
1. Versuch zunächst, einen Endpunkt wie `groups` aufzurufen, auf den du keine Rechte haben solltest:

   `Invoke-EntraRequest -Path Groups`
1. Jetzt wird es spezieller: Die App hat die Rolle, um alle Rechte zu lesen. Kannst du das mit deiner interaktiven Anmeldung
   auch?

   `Invoke-EntraRequest -Path applications`
1. Nö! Ein Fehler tritt auf. Scheint so, als würde uns noch ein Puzzleteil fehlen.


## Streng geheim

Die dritte Komponente auf unserem Weg hin zu einer Help Desk App sind Credentials! Warum eigentlich? Wir konnten
uns doch schon anmelden, oder etwa nicht? Na ja: Interaktiv konnten wir das. Aber um als Automation im Hintergrund zu laufen, ohne
von MFA-Prompts und CA-Policies belästigt zu werden, braucht es noch etwas: Secrets!

Melden wir uns mit Secrets an einer App an, erhalten wir ein anderes Set an Berechtigungen, die App-Rollen. Also,
mit unseren Secrets können wir uns als die Applikation ausgeben!

>HINWEIS: Wir erstellen zwar alle drei Secret-Typen, aber in der Praxis solltest du nach Möglichkeit auf Managed Identities
>und Federated Credentials setzen. Zertifikate und Kennwörter gehen gerne mal verloren, Workload Identity Federation
>verringert das Risiko.

### Client Secret

Client Secrets sind exakt das: Ein statische Secret, gemeinhin Passwort genannt, mit Ablaufdatum! Legen wir doch direkt mal eines an:

1. Wie immer starten wir mit der [API-Doku](https://learn.microsoft.com/en-us/graph/api/application-addpassword?view=graph-rest-1.0&tabs=http). Applikationen
   unterstützen allerhand Secrets!
   >HINWEIS: Schau dir genau die Request-Parameter an: Alle optional - so lässt es sich arbeiten.
1. Passwort anlegen und in einer Variablen speichern: `$clientSecret = Invoke-EntraRequest -Path applications/$($app.id)/addPassword -ContentType application/json`
1. `$clientSecret.secretText` beinhaltet nun das Klartext-Secret. Versuch doch mal, dich damit einzuloggen!
   <details>
   <summary>Zeig mir, wie das geht</summary>

   `Connect-EntraService -Service Graph -ClientId $app.appId -ClientSecret ($clientSecret.secretText | ConvertTo-SecureString -AsPlaintext -Force) -TenantId (Get-AzContext).Tenant.Id`
   </details>
1. Hat alles geklappt, können wir uns nun als App ausgeben. Unsere Rolle war`Application.Read.All`, also versuch mal, ein paar Apps auszulesen!

   `Invoke-EntraRequest -Path applications`
1. Gute Arbeit! Wenn du an unser Ziel denkst, abgelaufene Secrets zu finden, wie würdest du vorgehen.
   <details>
   <summary>Was weiß ich, zeig es mir halt</summary>

   ```powershell
   # App auffrischen
   $app = Invoke-EntraRequest -Path "applications/$($app.Id)"

   # Password-Secrets holen - ohne das Passwort natürlich
   $app.passwordCredentials
   ```
   </details>
1. Glückwunsch. Mal gucken, ob wir auch ein Zertifikat erstellen können!

### Certificate

X509-Zertifikate, also Schlüsselpaare, sind minimal komplizierter zu erstellen, haben aber den
scheinbaren Sicherheitsvorteil: Das Zertifikat kann in einem speziellen Store gespeichert werden,
oder auf einer Smartcard landen.

Nutzt man die Apps in Pipelines, hat das Zertifikat eigentlich keinen Vorteil mehr, da es zur Laufzeit der Pipeline verwendet
werden muss, und so kaum sicherer ist, als ein Client Secret.

Aber uns interessiert Sicherheit nicht, wir erstellen trotzdem eines! Euer Trainer nutzt Linux und verzichtet auf den Komfort von `New-SelfSignedCertificate`, aber ihr dürft natürlich
auch gerne damit arbeiten.

1. Als erstes brauchen wir das Zertifikat. In der echten Welt natürlich aus einer CA. Folgende Anforderungen gelten:
   - Es **muss** RSA sein, Entra ID unterstützt trotz der Reife und Effizient noch keine Elliptischen Kurven
   - Das Schlüsselmaterial sollte 2048 Bytes groß sein "aus Performance-Gründen" - Ich würde trotzdem 4096 oder sogar 8192 Bytes empfehlen.
   - Der Hash-Algorithmus muss SHA256, SHA384, oder SHA512 sein
1. Für diese Demo reicht uns auch ein selbstsigniertes Zertifikat. Windows-Freunde: [Hier ist eine Anleitung](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-self-signed-certificate)
   ```bash   
    openssl genrsa -out graphzahl.key 4096
    openssl req -new -key graphzahl.key -out graphzahl.csr -subj "/CN=GraphAutomationForFunAndProfit"
    openssl x509 -req -days 365 -in graphzahl.csr -signkey graphzahl.key -out graphzahl.crt
   ```
1. In unserem Request-Body hätten wir gerne unsere Zertifikat-Bytes als Base64-String.
   <details>
   <summary>Keine Lust, nun zeig schon</summary>

   ```powershell
   $body = @{
      keyCredentials = @(
         @{
               type        = 'AsymmetricX509Cert'
               usage       = 'Verify'
               key         = ((get-content ./graphzahl.crt -Raw) -replace '-*(BEGIN|END).*' -replace '\s+')
               displayName = "PowerShellIsAwesome"
         }
      )
   }
   ```
   </details>
1. Mit dem Request Body kann es auch schon losgehen
   <details>
   <summary>Nun mach schon</summary>

   `Invoke-EntraRequest -Method Patch -Path applications/$($app.id) -Body $body -ContentType application/json`
   </details>
1. Um die Anmeldung durchzuführen, signieren wir unseren Request mit unserem privaten Schlüssel. Auf dem Linux-Client eures
   Trainers muss zunächst ein PFX-File erzeugt werden, das könnt ihr euch auf Windows klemmen.

   ```powershell
   openssl pkcs12 -inkey graphzahl.key -in graphzahl.crt -export -out graphzahl.pfx -passout pass:
   Connect-EntraService -Service Graph -Certificate ./graphzahl.pfx -ClientId $app.appId -TenantId (Get-AzContext).Tenant.Id
   ```
1. Erfolg! Als nächstes träumen wir von einer Welt ganz ohne Credentials!


### Workload Identity Federation (Federated Credential)

Meiner Ansicht nach ist das Federated Credential der Gold-Standard der Authentifizierungs-Möglichkeiten. Zu keinem
Zeitpunkt muss irgendwer mit Secrets oder Zertifikaten herumfuhrwerken. Stattdessen vertrauen wir einem
externen Identitätsprovider wie Azure DevOps oder GitHub, einen Access Token für ein Objekt unter seiner Kontrolle
anzufragen und zu erhalten.

Also, legen wir eines an! Damit das klappt, brauchen wir erst mal einen externen IdP. Der Einfachheit halber
nehmen wir GitHub, da die meisten sicher bereits einen Account haben. Überspring dieses Kapitel einfach, wenn
du keinen Account hast.


1. GitHub Repo erstellen
1. Zwei Repo-Secrets erstellen:
   - AZURE_CLIENT_ID: Die AppId deiner App
   - AZURE_TENANT_ID: Die Tenant Id deiner App
1. Erstelle einen Workflow, indem du das Beispiel `.github/workflows/oidc.yml` kopierst.
1. Um nun das [Federated Credential](https://learn.microsoft.com/en-us/graph/api/federatedidentitycredential-post?view=graph-rest-1.0&tabs=http), zu erstellen, benötigen wir
   Informationen des externen IdP. Für GitHub ist das:
   - issuer: `https://token.actions.githubusercontent.com`
   - audience: `api://AzureADTokenExchange`
   - subject_claim hängt vom IdP ab. Bitte beachtet, dass ich meine org `nyanhp`und mein Repo `entraauthtest` nutze:
      - Ein Branch: `repo:nyanhp/entraauthtest:ref:refs/heads/main`
      - Ein Environment: `repo:nyanhp/entraauthtest:environment:prod`
      - Ein Git Tag: `repo:nyanhp/entraauthtest:ref:refs/tags/release`
      - Ein Pull Request: `repo:nyanhp/entraauthtest:pull_request`
1. Wir nehmen unseren Main Branch als subject claim. Aber ihr seht sicher: Eine Applikation mit Leserechten könnte
   für einen PR genutzt werden, während die Applikation mit schreibenden Rechten das Deployment aus Main heraus durchführt.

   Alles klar, erstell den Request Body!
   <details>
   <summary>Yalla, yalla!</summary>

   ```powershell
   $body = @{
      audiences = @(
         'api://AzureADTokenExchange'
      )
      issuer    = 'https://token.actions.githubusercontent.com'
      name      = 'deploy-from-main'
      subject   = 'repo:nyanhp/entraauthtest:ref:refs/heads/main'
   }
   ```
   </details>
1. Ein letzter POST: `Invoke-EntraRequest -Method Post -Path applications/$($app.id)/federatedIdentityCredentials -Body $body -ContentType application/json`
1. Um die Anmeldung zu testen, erzeug einen Commit und pushe - Der Workflow sollte direkt starten, und dir eine App ausgeben!


## OData Query Parameter

Nicht alle Graph-Ressourcen sind gleich. Manche API-Endpunkte unterstützen unterschiedliche 
[Query Parameter](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http). In diesem
Follow-Along habe ich die ausgewählt, die ich für wichtig halte. Kann man sich drüber streiten.

Wozu brauchen wir diese Parameter denn überhaupt? Wir könnten doch auch einfach mit `Where-Object` filtern!
Der Grund ist immer der gleiche, wie z.B. bei Active Directory oder SQL: Alle Objekte ungefiltert abzurufen,
sorgen in der Regel für unnötige Last in den Quellsystemen. Aber denkt das noch ein wenig weiter: Was, wenn eure
API ein Rate-Limit hat, oder pro Anzahl an Requests Geld kostet? Das alte PowerShell-Mantra "So früh wie möglich filtern" ist
auch hier noch relevant.

Query Parameter werden durch ein `$`-Symbol eingeleitet, also denk daran, es gegebenenfalls mit einem Backtick zu maskieren.

### Select

Ähnlich zu Select-Object können wir eine Untermenge von Attributen selektieren. So schränken wir effektiv die übertragene
Datenmenge ein. Da wir eigentlich nur passwordCredentials, keyCredentials, id, appId und displayName, können wir darauf filtern.

1. Ist nicht wirklich komplex: `$app = Invoke-EntraRequest -Path "applications/$($app.Id)?``$select=passwordCredentials,keyCredentials,id,appId,displayName"`
1. Das war's schon!

So, nun wird es interessanter, wir expandieren!

### Expand

Der expand Query Parameter kann relationale Attribute auflösen, wie zum Beispiel die federated Credentials einer Applikation.

Und genau das machen wir doch direkt!

1. Zu nächst holen wir uns noch mal die aktuellen Werte der App: `$app = Invoke-EntraRequest -Path "applications/$($app.Id)"`
1. Kannst du die Federated Credentials schon finden?
1. Schade, Schokolade. Was passiert denn, wenn wir das Attribut `$select`ieren? `$app = Invoke-EntraRequest -Path "applications/$($app.Id)?``$select=federatedIdentityCredentials"`
1. Immer noch nichts. Und was bringt der Expand? `$app = Invoke-EntraRequest -Path "applications/$($app.Id)?``$expand=federatedIdentityCredentials"`
1. Aha! Das relationale Attribut wird aufgelöst, und wir erhalten auch die Federated Credentials.

### Filter

Der Filter-Parameter ist super hilfreich, aber seine Syntax ist ... gewöhnungsbedürftig. Wir können die Daten jedoch
bereits an der Quelle filtern.

Wir starten erst mal einfach, mit einem Filter auf dem Anzeigenamen.

1. Wir ziehen uns alle Apps, und filtern auf den Anzeigenamen: `Invoke-EntraRequest "applications?``$filter=displayName eq 'PSConf Anniversary: Graph 101'"`
1. Natürlich kann ich Filter auch kombinieren: `Invoke-EntraRequest "applications?``$filter=startswith(displayName, 'PSConf') or endsWith(displayName, '101')"`
   >Oh nein! Alles wird rot! Jetzt erst mal Lesen...
   >Um endsWith zu nutzen, müssen wir den ConsistencyLevel auf eventual setzen. Das bedeutet: Wir überspringen eventuell App-Registrations, die noch nicht repliziert sind.
1. Header hinzugefügt, und schon geht's wieder los: `Invoke-EntraRequest "applications?``$filter=startswith(displayName, 'PSConf') or endsWith(displayName, '101')" -Header @{ConsistencyLevel = 'eventual'}`
1. Nice. Jetzt mal was interessanteres: Gezählte Attributs-Werte im Filter nutzen. In der Doku sehen wir, dass sich die relationalen Attribute
   zählen lassen, also filtern wir alle Apps mit Federated Credentials.

   >Wicihtig: In PowerShell würden wir instinktiv mit z.b. größer als vergleichen. Auch wenn Graph `ge` unterstützt, tut es das Attribut
   >`federatedIdentityCredentials` noch lange nicht!

   ```powershell
   Invoke-EntraRequest 'applications?$filter=federatedIdentityCredentials/$count ne 0&$count=true' -Header @{ConsistencyLevel = 'eventual'}
   ```
1. Wunderbar! Wir sind faaaaaast durch.

## So wird ein Schuh draus

Machen wir's einfach: Kopier den kompletten OIDC-Workflow in dein Repo und ersetz' den alten Workflow. Der Code ist simpel genug, um
auf der PSConfEU verstanden zu werden!

Commit, Push, und werde Zeuge, wie die ganze Arbeit endlich ein Ergebnis liefert!

## Abschließende Bemerkungen

✅ Wir haben einen Workflow, der abgelaufene Secrets findet.
✅ Unser helpdesk kann Windows Hello zurücksetzen.
✅ Wir halten uns an das Principle of Least Privilege
✅ Wir haben sichere Credentials für unsere App angelegt

Hiervon ausgehend könnt ihr nach Herzenslust eure App anpassen und neue erstellen, um euren Automations-Anforderungen zu genügen. Mit
Ressourcen wie Azure Automation Runbooks müsstet ihr euch nicht einmal mit Federated Credentials beschäftigen, da die Plattform
alles für euch macht.
