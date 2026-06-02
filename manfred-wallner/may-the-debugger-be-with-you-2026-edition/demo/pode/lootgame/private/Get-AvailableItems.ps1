
function Get-AvailableItems {
  1..1000 | ForEach-Object {
    Get-Random -InputObject @('❄', '❓', '☕', '⚠', '⚡')
  }
}
