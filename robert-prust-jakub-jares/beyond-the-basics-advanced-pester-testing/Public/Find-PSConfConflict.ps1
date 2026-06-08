function Find-PSConfConflict {
    <#
    .SYNOPSIS
        Detects time-overlap pairs in a set of sessions.

    .DESCRIPTION
        Pure function — no API calls. Takes any collection of PSConfSession-shaped
        objects (each must have an Id and [datetime] StartTime/EndTime), then
        emits one PSConfConflict per overlapping pair.

        Overlap definition: `(a.StartTime < b.EndTime) AND (b.StartTime < a.EndTime)`.
        Back-to-back sessions where one ends exactly when the next starts are
        NOT conflicts (the boundary is exclusive).

        For N sessions, output can contain up to N*(N-1)/2 pairs. Returns
        nothing if there are no conflicts.

    .PARAMETER Session
        Array of session objects to check. Typically the output of
        `Get-PSConfSession` with filters applied.

    .EXAMPLE
        $picks = Get-PSConfSession -Track Testing -Day '2026-05-19'
        Find-PSConfConflict -Session $picks

        Verify the talks you want to attend on a track don't clash.

    .EXAMPLE
        $clashes = Find-PSConfConflict -Session (Get-PSConfSession)
        $clashes | Format-Table First, Second

        Sanity-check the entire programme for any time conflicts at all —
        useful for organisers, not just attendees.

    .EXAMPLE
        # Decide which of two simultaneous sessions to attend
        $candidates = Get-PSConfSession -Day '2026-05-19' |
            Where-Object Track -in 'Testing','Modules'
        $clashes = Find-PSConfConflict -Session $candidates
        if ($clashes) {
            "You can't attend everything. Conflicts:"
            $clashes
        }

    .OUTPUTS
        PSConfConflict — each object has `First` and `Second` (the two session ids
        that overlap).

    .LINK
        Get-PSConfSession
    #>
    [CmdletBinding()]
    [OutputType('PSConfConflict')]
    param(
        # Sessions are expected to be PSConfSession-shaped (PascalCase Id,
        # StartTime, EndTime — StartTime/EndTime are [datetime]).
        [Parameter(Mandatory)]
        [object[]] $Session
    )

    $sorted = $Session | Sort-Object -Property Id

    for ($i = 0; $i -lt $sorted.Count - 1; $i++) {
        for ($j = $i + 1; $j -lt $sorted.Count; $j++) {
            $a = $sorted[$i]
            $b = $sorted[$j]
            if ($a.StartTime -lt $b.EndTime -and $b.StartTime -lt $a.EndTime) {
                [pscustomobject]@{
                    PSTypeName = 'PSConfConflict'
                    First      = $a.Id
                    Second     = $b.Id
                }
            }
        }
    }
}
