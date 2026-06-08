function Register-PSConfAttendee {
    <#
    .SYNOPSIS
        Registers a new attendee with the conference API.

    .DESCRIPTION
        POSTs an attendee record (name, email, company) and returns the created
        PSConfAttendee, including the server-assigned Id (e.g. A001).

        Client-side validation only catches obviously broken email shapes — the
        API does the rest (uniqueness, deny-list, etc.) and surfaces failures as
        terminating errors (`PSConfEU API call failed: 400 (Bad Request)`).

    .PARAMETER Name
        Attendee's display name. Empty string is allowed at bind time so the
        server can be the final arbiter (see workshop notes on AllowEmptyString).

    .PARAMETER Email
        Attendee's email address. Must match `^[^@\s]+@[^@\s]+\.[^@\s]+$`
        client-side. Server may apply stricter rules.

    .PARAMETER Company
        Company / employer name. Free-form string.

    .EXAMPLE
        Register-PSConfAttendee -Name 'Robert' -Email 'robert@example.com' -Company 'Wortell'

        The minimum-effort registration call. Returns the PSConfAttendee object,
        including the new Id you'll need for follow-up actions.

    .EXAMPLE
        $me = Register-PSConfAttendee -Name 'Robert' -Email 'r@x.com' -Company 'Wortell'
        Submit-PSConfRating -SessionId S001 -Stars 5 -Comment "Loved it, signed off by $($me.Id)"

        Capture the returned attendee, then act on its Id.

    .OUTPUTS
        PSConfAttendee

    .LINK
        Submit-PSConfRating
    #>
    [CmdletBinding()]
    [OutputType('PSConfAttendee')]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Name,
        [Parameter(Mandatory)] [string] $Email,
        [Parameter(Mandatory)] [string] $Company
    )

    if ($Email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        throw "Email '$Email' does not look like a valid address."
    }

    $apiParams = @{
        Path   = '/attendees'
        Method = 'Post'
        Body   = @{
            name    = $Name
            email   = $Email
            company = $Company
        }
    }

    Invoke-PSConfApi @apiParams | ConvertTo-PSConfAttendee
}
