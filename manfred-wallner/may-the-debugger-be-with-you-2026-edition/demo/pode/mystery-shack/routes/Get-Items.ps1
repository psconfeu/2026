
{
  $inventory = Get-PodeState -Name 'shopItems'

  Write-PodeJsonResponse -Value @{
    store = 'Mystery Shack Gift Shop'
    items = $inventory
  }
}
