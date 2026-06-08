function Submit-PSConfRating {
    <#
    .SYNOPSIS
        Submits a 1-5 star rating (with an optional comment) for a session.

    .DESCRIPTION
        POSTs a rating to /ratings and returns the created PSConfRating.

        Validates -Stars locally (1-5, integer) and short-circuits before
        making the API call if it's out of range. On a transient `429 Too Many
        Requests` from the server, retries exactly once; any other error
        propagates.

    .PARAMETER SessionId
        Session id to rate (e.g. S001). The server 404s for unknown ids.

    .PARAMETER Stars
        Integer rating from 1 (worst) to 5 (best). Anything else throws before
        the API is called.

    .PARAMETER Comment
        Optional free-form comment to attach to the rating.

    .EXAMPLE
        Submit-PSConfRating -SessionId S001 -Stars 5 -Comment 'great talk!'

        The most common pattern — rate a session right after it ends.

    .EXAMPLE
        Get-PSConfSession -Track Testing -Day '2026-05-19' |
            ForEach-Object { Submit-PSConfRating -SessionId $_.Id -Stars 5 -Comment "Loved $($_.Title)" }

        Bulk-rate every session on a track at the end of the day.

    .EXAMPLE
        try {
            Submit-PSConfRating -SessionId 'BOGUS' -Stars 5 -Comment 'oops'
        }
        catch {
            "API rejected: $_"
        }

        Showing the error path — unknown session ids surface as `404`.

    .OUTPUTS
        PSConfRating

    .LINK
        Get-PSConfSession
        Register-PSConfAttendee
    #>
    [CmdletBinding()]
    [OutputType('PSConfRating')]
    param(
        [Parameter(Mandatory)]
        [string] $SessionId,

        [Parameter(Mandatory)]
        [int] $Stars,

        [string] $Comment
    )

    if (-not (Test-PSConfRating -Stars $Stars)) {
        throw "Stars must be an integer between 1 and 5 (got: $Stars)"
    }

    $apiParams = @{
        Path   = '/ratings'
        Method = 'Post'
        Body   = @{
            sessionId = $SessionId
            stars     = $Stars
            comment   = $Comment
        }
    }

    # Single retry on transient failure (e.g., 429). Workshop discusses this in the
    # 'advanced mocking with sequenced responses' chapter.
    try {
        Invoke-PSConfApi @apiParams | ConvertTo-PSConfRating
    }
    catch {
        if ($_.Exception.Message -match '429') {
            Invoke-PSConfApi @apiParams | ConvertTo-PSConfRating
        }
        else {
            throw
        }
    }
}
