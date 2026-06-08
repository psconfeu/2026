function ConvertTo-PSConfLocalTime {
    <#
    .SYNOPSIS
        Formats a UTC ISO-8601 string as Europe/Amsterdam local time with CET/CEST suffix.

    .DESCRIPTION
        Parses an ISO-8601 UTC timestamp, converts it to Europe/Amsterdam local
        time, and formats it as `yyyy-MM-dd HH:mm CET|CEST` — picking the right
        abbreviation based on whether the resulting local time falls inside
        daylight-saving.

        Used in the workshop's chapter-2 example for DST-aware data-driven tests.

        Private — not exported.

    .PARAMETER Utc
        ISO-8601 timestamp ending in `Z`, e.g. '2026-05-19T08:00:00Z'. Parsed
        with `[cultureinfo]::InvariantCulture` so it works regardless of the
        host's locale settings.

    .EXAMPLE
        ConvertTo-PSConfLocalTime -Utc '2026-01-15T09:00:00Z'

        Returns '2026-01-15 10:00 CET' — winter in Amsterdam is UTC+1.

    .EXAMPLE
        ConvertTo-PSConfLocalTime -Utc '2026-05-19T08:00:00Z'

        Returns '2026-05-19 10:00 CEST' — summer is UTC+2, so the conference's
        08:00 UTC keynote is 10:00 local.

    .EXAMPLE
        Get-PSConfSession -Day '2026-05-19' |
            ForEach-Object {
                "{0}  {1}" -f (ConvertTo-PSConfLocalTime -Utc $_.StartTime.ToString('o')), $_.Title
            }

        Render a session list in local time (rather than the UTC the API returns).

    .OUTPUTS
        System.String — formatted local time, e.g. '2026-05-19 10:00 CEST'.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Utc
    )

    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById('Europe/Amsterdam')
    $utcDt = [datetime]::Parse($Utc, [cultureinfo]::InvariantCulture).ToUniversalTime()
    $local = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDt, $tz)

    # CET in winter, CEST in summer
    $abbr = if ($tz.IsDaylightSavingTime($local)) { 'CEST' } else { 'CET' }

    return '{0:yyyy-MM-dd HH:mm} {1}' -f $local, $abbr
}
