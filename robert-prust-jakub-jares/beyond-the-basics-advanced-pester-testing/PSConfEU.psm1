$ErrorActionPreference = 'Stop'

# Dot-source every .ps1 in Private/ and Public/
foreach ($folder in 'Private', 'Public') {
    Get-ChildItem -Path (Join-Path $PSScriptRoot $folder) -Filter '*.ps1' -ErrorAction SilentlyContinue |
        ForEach-Object { . $_.FullName }
}

# Resolve and cache the API base URL on load.
# Tests override via:  InModuleScope PSConfEU { $script:PSConfApiBase = '...' }
$script:PSConfApiBase = Get-PSConfApiBase
