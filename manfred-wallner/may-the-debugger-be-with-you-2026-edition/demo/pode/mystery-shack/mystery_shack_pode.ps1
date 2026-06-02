<#
.SYNOPSIS
    Mystery Shack Gift Shop API — Pode demo for "May the Debugger Be With You 2026".

.DESCRIPTION
    A simple Pode web server simulating the Mystery Shack online gift shop.

.EXAMPLE
    # List all items
    Invoke-RestMethod http://localhost:8181/items

    # Cheap items only
    Invoke-RestMethod http://localhost:8181/cart/total -Method Post `
        -ContentType 'application/json' `
        -Body '{"items":[{"id":1,"quantity":1},{"id":2,"quantity":1},{"id":3,"quantity":1}]}'

    # Premium item
    Invoke-RestMethod http://localhost:8181/cart/total -Method Post `
        -ContentType 'application/json' `
        -Body '{"items":[{"id":5,"quantity":1}]}'
#>
param(
  [ValidateRange(1024, 65535)]
  [int]$Port = 8181
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module Pode -ErrorAction Stop

$shopItems = @(
  [ordered]@{ Id = 1; Name = "Grunkle Stan's Fez"; Price = 24.99 }
  [ordered]@{ Id = 2; Name = "Mabel's Sweater (Shooting Star)"; Price = 39.99 }
  [ordered]@{ Id = 3; Name = "Dipper's Pine Tree Cap"; Price = 19.99 }
  [ordered]@{ Id = 4; Name = "Soos's Question Mark Shirt"; Price = 29.99 }
  [ordered]@{ Id = 5; Name = "Dipper's Journal #3 Replica"; Price = 109.99 }
  [ordered]@{ Id = 6; Name = 'Mystery Shack Snow Globe'; Price = 149.99 }
  [ordered]@{ Id = 7; Name = "Robbie's Guitar Pick Set"; Price = 9.99 }
)

$getItemsRoutePath = (Join-Path $PSScriptRoot 'routes/Get-Items.ps1')
$postCartTotalRoutePath = (Join-Path $PSScriptRoot 'routes/Post-CartTotal.ps1')


Start-PodeServer -Threads 1 -ScriptBlock {

  Set-PodeState -Name 'shopItems' -Value $shopItems

  Add-PodeEndpoint -Address '*' -Port $Port -Protocol Http

  New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

  Add-PodeBodyParser -ContentType 'application/json' -ScriptBlock {
    param($body)
    if ([string]::IsNullOrWhiteSpace($body)) { return @{} }
    return ($body | ConvertFrom-Json -AsHashtable -Depth 10)
  }

  Add-PodeRoute -Method Get -Path '/items' -FilePath $getItemsRoutePath
  Add-PodeRoute -Method Post -Path '/cart/total' -FilePath $postCartTotalRoutePath
}
