[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Value,

    [Parameter()]
    [string]
    $ConsoleEncoding = 'utf-8'
)

[Console]::OutputEncoding = [Text.Encoding]::GetEncoding($ConsoleEncoding)

[Text.UTF8Encoding]::new().GetString([Convert]::FromBase64String($Value))
