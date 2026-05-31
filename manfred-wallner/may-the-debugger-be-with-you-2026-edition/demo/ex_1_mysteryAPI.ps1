[CmdletBinding()]
param(
  [string]$BaseUrl = 'http://localhost:8181'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


Write-Host 'Mystery Shack Webshop Rip-Off'

Write-Host '1. Fetch shop items'
$items = try {
  Invoke-RestMethod -Uri "$BaseUrl/items" -Method Get
}
catch {
  Write-Host "Please ensure the Mystery Shack Pode server is running and accessible at $BaseUrl" -ForegroundColor Yellow
  Write-Error "Failed to fetch items: $_"
  exit 1
}
$items.items | Select-Object Id, Name, Price | Format-Table -AutoSize

Write-Host '2. Calculate a normal cart total'
$shoppingCart = @{
  items = @(
    @{ id = 1; quantity = 1 }
    @{ id = 2; quantity = 1 }
    @{ id = 3; quantity = 1 }
  )
}

$irmArgs = @{
  Uri         = "$BaseUrl/cart/total"
  Method      = Post
  ContentType = 'application/json'
  Body        = ($shoppingCart | ConvertTo-Json -Depth 5)
}
$cheapResponse = Invoke-RestMethod @irmArgs
$cheapResponse | Format-List

Write-Host '3. Calculate the premium cart total'
$shoppingCart = @{
  items = @(
    @{ id = 5; quantity = 1 }
  )
}
$irmArgs.Body = ($shoppingCart | ConvertTo-Json -Depth 5)
$premiumResponse = Invoke-RestMethod @irmArgs
$premiumResponse | Format-List

Write-Host '4. Compare expected and actual totals'
# Note the following line is crap when there are multiple items in the cart
$expectedOriginalPrice = ($items.items | Where-Object { $_.Id -eq $shoppingCart.items.id }).Price 
$expectedDiscount = $expectedOriginalPrice * 0.15
$expectedFinalPrice = [math]::Round($expectedOriginalPrice - $expectedDiscount, 2)

Write-Host ('Expected discount: {0:n4}' -f $expectedDiscount)
Write-Host ('Expected total:    {0:n2}' -f $expectedFinalPrice)
Write-Host ('Actual total:      {0:n2}' -f $premiumResponse.total)
Write-Host ('Difference:        {0:n2}' -f ($premiumResponse.total - $expectedFinalPrice))
