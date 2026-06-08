function Invoke-PSConfApi {
    <#
    .SYNOPSIS
        Central HTTP wrapper for the PSConfEU module — every cmdlet routes through here.

    .DESCRIPTION
        Thin shim over `Invoke-RestMethod`. Three jobs:

        1. Builds the full URL from `$script:PSConfApiBase` + `-Path`, appending
           a URL-encoded query string when `-Query` is given.
        2. Serializes `-Body` to JSON and sets `Content-Type: application/json`
           when a body is provided.
        3. Normalizes failures by re-throwing the inner exception's message as
           a single string starting with `PSConfEU API call failed:`. Callers
           can match on `*404*`, `*429*`, etc.

        Centralising HTTP here means **every** unit test mocks exactly one thing,
        not Invoke-RestMethod scattered across the module. That's the workshop's
        main mocking lesson.

        Private — not exported.

    .PARAMETER Path
        Path component after the base URL, e.g. '/sessions' or '/sessions/S001'.

    .PARAMETER Method
        HTTP verb. One of Get, Post, Put, Delete. Defaults to Get.

    .PARAMETER Query
        Optional key/value pairs to URL-encode into a query string. Accepts
        any IDictionary — pass `[ordered]@{}` when key order matters for tests.

    .PARAMETER Body
        Optional payload. Serialized to JSON with `ConvertTo-Json -Depth 6`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/sessions'

        Plain GET. Returns whatever Invoke-RestMethod parses out of the response.

    .EXAMPLE
        Invoke-PSConfApi -Path '/sessions' -Query @{ speakerId = 'SP07'; day = '2026-05-19' }

        GET with filters. Produces a URL like:
            http://localhost:5000/sessions?speakerId=SP07&day=2026-05-19

    .EXAMPLE
        Invoke-PSConfApi -Path '/ratings' -Method Post -Body @{
            sessionId = 'S001'
            stars     = 5
            comment   = 'great'
        }

        POST with a JSON body.

    .EXAMPLE
        # In tests — mock this one function, not Invoke-RestMethod
        InModuleScope PSConfEU {
            Mock Invoke-PSConfApi { @() }
            Get-PSConfSession -Track Testing
            Should -Invoke Invoke-PSConfApi -ParameterFilter {
                $Path -eq '/sessions' -and $Query.track -eq 'Testing'
            }
        }

    .OUTPUTS
        Whatever the API endpoint returns (parsed by Invoke-RestMethod).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [ValidateSet('Get','Post','Put','Delete')]
        [string] $Method = 'Get',

        # Intentionally untyped so callers can pass [ordered]@{} for deterministic
        # query-string ordering — useful when tests assert key order. A [hashtable]
        # constraint would coerce OrderedDictionary back, defeating the purpose.
        $Query,

        [object] $Body
    )

    $uri = $script:PSConfApiBase.TrimEnd('/') + $Path

    if ($Query -and $Query.Count -gt 0) {
        $pairs = foreach ($k in $Query.Keys) {
            '{0}={1}' -f [uri]::EscapeDataString($k), [uri]::EscapeDataString([string]$Query[$k])
        }
        $uri = $uri + '?' + ($pairs -join '&')
    }

    $params = @{
        Uri    = $uri
        Method = $Method
    }
    if ($PSBoundParameters.ContainsKey('Body')) {
        $params.Body        = $Body | ConvertTo-Json -Depth 6 -Compress
        $params.ContentType = 'application/json'
    }

    try {
        Invoke-RestMethod @params
    }
    catch {
        throw "PSConfEU API call failed: $($_.Exception.Message)"
    }
}
