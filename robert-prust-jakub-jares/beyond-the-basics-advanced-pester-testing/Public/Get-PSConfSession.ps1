function Get-PSConfSession {
    <#
    .SYNOPSIS
        Lists conference sessions, with optional server-side filters.

    .DESCRIPTION
        Fetches sessions from the PSConfEU API and returns each as a PSConfSession
        object with PascalCase properties and [datetime] StartTime/EndTime.

        Any combination of -Speaker, -Track, -Day, and -Room narrows the result.
        Omitting all four returns the full session list.

    .PARAMETER Speaker
        Speaker id (e.g. SP07). Filters to sessions where speakerId matches.

    .PARAMETER Track
        Track name (e.g. Testing, Modules, Platform). Exact match, case-sensitive
        on the server.

    .PARAMETER Day
        ISO date (YYYY-MM-DD) of the conference day.

    .PARAMETER Room
        Room id (e.g. R1, R2).

    .EXAMPLE
        Get-PSConfSession

        Returns every session for the conference, typed as PSConfSession.

    .EXAMPLE
        Get-PSConfSession -Track Testing -Day '2026-05-19'

        Returns only Testing-track sessions on day one — handy for picking a
        track to follow for the day. Pair with Find-PSConfConflict to check for
        time clashes:

            $picks = Get-PSConfSession -Track Testing -Day '2026-05-19'
            Find-PSConfConflict -Session $picks

    .EXAMPLE
        Get-PSConfSession -Speaker SP07 |
            Sort-Object StartTime |
            Select-Object Day, StartTime, Title

        Lists every session by a specific speaker, chronologically — useful for
        "where am I supposed to be next?" workflows.

    .OUTPUTS
        PSConfSession

    .LINK
        Find-PSConfConflict
        Submit-PSConfRating
    #>
    [CmdletBinding()]
    [OutputType('PSConfSession')]
    param(
        [string] $Speaker,
        [string] $Track,
        [string] $Day,
        [string] $Room
    )

    # [ordered] preserves insertion order through to Invoke-PSConfApi so query strings
    # come out deterministically (handy for tests that assert exact key order).
    $query = [ordered]@{}
    if ($Speaker) { $query.speakerId = $Speaker }
    if ($Track)   { $query.track     = $Track }
    if ($Day)     { $query.day       = $Day }
    if ($Room)    { $query.room      = $Room }

    $apiParams = @{ Path = '/sessions' }
    if ($query.Count -gt 0) { $apiParams.Query = $query }

    $now = (Get-Date).ToUniversalTime()

    Invoke-PSConfApi @apiParams | ConvertTo-PSConfSession | ForEach-Object {
        $_ | Add-Member -NotePropertyName TimeUntilSession `
                        -NotePropertyValue ($_.StartTime - $now) `
                        -PassThru
    }
}
