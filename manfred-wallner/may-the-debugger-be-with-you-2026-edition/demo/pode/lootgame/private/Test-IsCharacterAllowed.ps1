function Test-IsCharacterAllowed {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $name
  )
  $matcher = Get-AvailableCharactersRegex
  $name -match $matcher | Out-Null
  if (-not $matches) {
    throw 'YOU SHALL NOT PASS'
  }
  $name
}
