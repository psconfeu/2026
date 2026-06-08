function Get-PSConfSchedule {
    <#
    .SYNOPSIS
        Returns the conference schedule with sessions joined to speakers and rooms.

    .DESCRIPTION
        Calls the API's /schedule endpoint, which serves a pre-joined view: each
        item already carries the speaker name and the room name (not just ids).
        Items come back sorted by start time across all days.

        Use this when you want a human-readable "what's on next" list rather than
        the raw session catalog (which is Get-PSConfSession).

    .EXAMPLE
        Get-PSConfSchedule | Select-Object Day, StartTime, Title, Speaker, Room

        Quick-look schedule for the whole event.

    .EXAMPLE
        Get-PSConfSchedule |
            Where-Object Day -EQ '2026-05-19' |
            Format-Table StartTime, Track, Title, Room -AutoSize

        Day-one schedule, formatted for printing.

    .EXAMPLE
        $now = (Get-Date).ToUniversalTime()
        Get-PSConfSchedule |
            Where-Object { $_.StartTime -gt $now } |
            Select-Object -First 3

        "What are the next three things happening?" — handy on stage.

    .OUTPUTS
        PSConfScheduleItem

    .LINK
        Get-PSConfSession
    #>
    [CmdletBinding()]
    [OutputType('PSConfScheduleItem')]
    param()
    Invoke-PSConfApi -Path '/schedule' | ConvertTo-PSConfScheduleItem
}
