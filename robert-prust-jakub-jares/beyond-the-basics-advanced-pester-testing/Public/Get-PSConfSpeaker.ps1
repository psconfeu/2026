function Get-PSConfSpeaker {
    <#
    .SYNOPSIS
        Gets one speaker by id, or lists speakers with optional filters.

    .DESCRIPTION
        Has two parameter sets:

        - **ById** — pass -Id to fetch exactly one speaker. 404 from the API
          surfaces as a terminating error.
        - **List** (default) — optional -Name and -Company filters, both
          exact-match on the server.

        Always returns PSConfSpeaker objects (typed PSCustomObject).

    .PARAMETER Id
        Speaker id (e.g. SP07). Mandatory in the ById parameter set.

    .PARAMETER Name
        Filters the list by speaker name (exact match).

    .PARAMETER Company
        Filters the list by employer.

    .EXAMPLE
        Get-PSConfSpeaker -Id SP07

        Fetches a single speaker.

    .EXAMPLE
        Get-PSConfSpeaker

        Lists every speaker.

    .EXAMPLE
        Get-PSConfSpeaker -Company Microsoft

        Lists everyone employed by Microsoft this year.

    .EXAMPLE
        $speaker = Get-PSConfSpeaker -Id SP07
        Get-PSConfSession -Speaker $speaker.Id

        Resolve a speaker, then list their sessions.

    .OUTPUTS
        PSConfSpeaker

    .LINK
        Get-PSConfSession
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType('PSConfSpeaker')]
    param(
        [Parameter(ParameterSetName = 'ById', Mandatory)]
        [string] $Id,

        [Parameter(ParameterSetName = 'List')]
        [string] $Name,

        [Parameter(ParameterSetName = 'List')]
        [string] $Company
    )

    if ($PSCmdlet.ParameterSetName -eq 'ById') {
        return Invoke-PSConfApi -Path "/speakers/$Id" | ConvertTo-PSConfSpeaker
    }

    $query = [ordered]@{}
    if ($Name)    { $query.name    = $Name }
    if ($Company) { $query.company = $Company }

    $apiParams = @{ Path = '/speakers' }
    if ($query.Count -gt 0) { $apiParams.Query = $query }

    Invoke-PSConfApi @apiParams | ConvertTo-PSConfSpeaker
}
