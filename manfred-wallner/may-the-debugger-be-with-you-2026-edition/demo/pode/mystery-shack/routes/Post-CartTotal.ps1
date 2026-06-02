{
  $body = $WebEvent.Data
  $cart = $body.items
  $inventory = Get-PodeState -Name 'shopItems'
  $total = 0.0
  $lineItems = @()

  foreach ($entry in $cart) {
    $item = $inventory | Where-Object { $_.Id -eq [int]$entry.id }

    if ($null -eq $item) {
      Set-PodeResponseStatus -Code 400
      Write-PodeJsonResponse -Value @{
        error = "Unknown item id: $($entry.id)"
      }
      return
    }

    $price = $item.Price
    $quantity = [int]$entry.quantity

    # Collector's discount: 15% off for items priced above $99.99
    if ($price -gt 99.99) {
      $discountAmount = [int]($price * 0.15)
      $price = $price - $discountAmount
    }

    $lineTotal = $price * $quantity
    $total += $lineTotal

    $lineItems += [ordered]@{
      id            = $item.Id
      name          = $item.Name
      originalPrice = $item.Price
      unitPrice     = [math]::Round($price, 2)
      quantity      = $quantity
      lineTotal     = [math]::Round($lineTotal, 2)
    }
  }

  Write-PodeJsonResponse -Value @{
    lineItems = $lineItems
    total     = [math]::Round($total, 2)
    currency  = 'USD'
  }
}
