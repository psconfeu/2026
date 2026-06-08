# Each converter accepts pipeline input AND handles being called with an array
# directly (e.g., when an upstream cmdlet emits a wrapped collection that doesn't
# unroll). Defensive `foreach ($obj in @($InputObject))` handles both cases.
#
# These functions are all private. They translate the wire-format JSON shape
# (lowercase keys, dates as strings) into the module's typed PowerShell objects
# (PSTypeName-tagged PSCustomObjects, PascalCase, [datetime] for times).

function ConvertTo-PSConfSession {
    <#
    .SYNOPSIS
        Converts a raw /sessions JSON object into a PSConfSession-typed object.

    .DESCRIPTION
        Wire-to-PowerShell mapping for sessions:

        | Wire (JSON)       | PowerShell (PSConfSession)     |
        |-------------------|------------------------------|
        | id (string)       | Id (string)                  |
        | title (string)    | Title (string)               |
        | speakerId         | SpeakerId                    |
        | track             | Track                        |
        | roomId            | RoomId                       |
        | day               | Day                          |
        | startTime (ISO)   | StartTime ([datetime] UTC)   |
        | endTime (ISO)     | EndTime ([datetime] UTC)     |

        Accepts pipeline input. Skips $null entries silently.

        Private — not exported.

    .PARAMETER InputObject
        Raw response object (or array of them) from `Invoke-PSConfApi`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/sessions' | ConvertTo-PSConfSession

        The canonical usage — pipe an Invoke-PSConfApi response through.

    .EXAMPLE
        $raw = Get-Content ./fixtures/sessions.json -Raw | ConvertFrom-Json
        $raw | ConvertTo-PSConfSession

        Works against any object with the right shape — useful in test fixtures.

    .OUTPUTS
        PSConfSession
    #>
    [CmdletBinding()]
    [OutputType('PSConfSession')]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach ($obj in @($InputObject)) {
            if ($null -eq $obj) { continue }
            [pscustomobject]@{
                PSTypeName = 'PSConfSession'
                Id         = $obj.id
                Title      = $obj.title
                SpeakerId  = $obj.speakerId
                Track      = $obj.track
                RoomId     = $obj.roomId
                Day        = $obj.day
                StartTime  = [datetime]::Parse($obj.startTime, [cultureinfo]::InvariantCulture).ToUniversalTime()
                EndTime    = [datetime]::Parse($obj.endTime,   [cultureinfo]::InvariantCulture).ToUniversalTime()
            }
        }
    }
}

function ConvertTo-PSConfSpeaker {
    <#
    .SYNOPSIS
        Converts a raw /speakers JSON object into a PSConfSpeaker-typed object.

    .DESCRIPTION
        Wire-to-PowerShell mapping for speakers:

        | Wire (JSON) | PowerShell (PSConfSpeaker) |
        |-------------|--------------------------|
        | id          | Id                       |
        | name        | Name                     |
        | company     | Company                  |
        | twitter     | Twitter                  |

        Private — not exported.

    .PARAMETER InputObject
        Raw response object (or array of them) from `Invoke-PSConfApi`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/speakers' | ConvertTo-PSConfSpeaker

    .OUTPUTS
        PSConfSpeaker
    #>
    [CmdletBinding()]
    [OutputType('PSConfSpeaker')]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach ($obj in @($InputObject)) {
            if ($null -eq $obj) { continue }
            [pscustomobject]@{
                PSTypeName = 'PSConfSpeaker'
                Id         = $obj.id
                Name       = $obj.name
                Company    = $obj.company
                Twitter    = $obj.twitter
            }
        }
    }
}

function ConvertTo-PSConfScheduleItem {
    <#
    .SYNOPSIS
        Converts a raw /schedule JSON item into a PSConfScheduleItem-typed object.

    .DESCRIPTION
        The /schedule endpoint serves a pre-joined view — each item already
        carries the speaker NAME and the room NAME, not just ids. This
        converter preserves those joined fields and adds [datetime] parsing.

        Private — not exported.

    .PARAMETER InputObject
        Raw schedule-item object (or array) from `Invoke-PSConfApi`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/schedule' | ConvertTo-PSConfScheduleItem

    .OUTPUTS
        PSConfScheduleItem
    #>
    [CmdletBinding()]
    [OutputType('PSConfScheduleItem')]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach ($obj in @($InputObject)) {
            if ($null -eq $obj) { continue }
            [pscustomobject]@{
                PSTypeName = 'PSConfScheduleItem'
                Id         = $obj.id
                Title      = $obj.title
                Track      = $obj.track
                Day        = $obj.day
                StartTime  = [datetime]::Parse($obj.startTime, [cultureinfo]::InvariantCulture).ToUniversalTime()
                EndTime    = [datetime]::Parse($obj.endTime,   [cultureinfo]::InvariantCulture).ToUniversalTime()
                Speaker    = $obj.speaker
                Room       = $obj.room
            }
        }
    }
}

function ConvertTo-PSConfAttendee {
    <#
    .SYNOPSIS
        Converts a raw /attendees JSON object into a PSConfAttendee-typed object.

    .DESCRIPTION
        Wire-to-PowerShell mapping for attendees:

        | Wire (JSON) | PowerShell (PSConfAttendee) |
        |-------------|---------------------------|
        | id          | Id                        |
        | name        | Name                      |
        | email       | Email                     |
        | company     | Company                   |

        Private — not exported.

    .PARAMETER InputObject
        Raw attendee object (or array) from `Invoke-PSConfApi`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/attendees' -Method Post -Body @{
            name = 'Robert'; email = 'r@x.com'; company = 'Wortell'
        } | ConvertTo-PSConfAttendee

    .OUTPUTS
        PSConfAttendee
    #>
    [CmdletBinding()]
    [OutputType('PSConfAttendee')]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach ($obj in @($InputObject)) {
            if ($null -eq $obj) { continue }
            [pscustomobject]@{
                PSTypeName = 'PSConfAttendee'
                Id         = $obj.id
                Name       = $obj.name
                Email      = $obj.email
                Company    = $obj.company
            }
        }
    }
}

function ConvertTo-PSConfRating {
    <#
    .SYNOPSIS
        Converts a raw /ratings JSON object into a PSConfRating-typed object.

    .DESCRIPTION
        Wire-to-PowerShell mapping for ratings:

        | Wire (JSON)      | PowerShell (PSConfRating)     |
        |------------------|-----------------------------|
        | id               | Id                          |
        | sessionId        | SessionId                   |
        | stars (Int64)    | Stars ([int])               |
        | comment          | Comment                     |

        Note: ConvertFrom-Json deserializes JSON integers as [long]/Int64; the
        converter normalises to [int] so downstream code can rely on the type.

        Private — not exported.

    .PARAMETER InputObject
        Raw rating object (or array) from `Invoke-PSConfApi`.

    .EXAMPLE
        Invoke-PSConfApi -Path '/ratings' -Method Post -Body @{
            sessionId = 'S001'; stars = 5; comment = 'great'
        } | ConvertTo-PSConfRating

    .OUTPUTS
        PSConfRating
    #>
    [CmdletBinding()]
    [OutputType('PSConfRating')]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach ($obj in @($InputObject)) {
            if ($null -eq $obj) { continue }
            [pscustomobject]@{
                PSTypeName = 'PSConfRating'
                Id         = $obj.id
                SessionId  = $obj.sessionId
                Stars      = [int]$obj.stars
                Comment    = $obj.comment
            }
        }
    }
}
