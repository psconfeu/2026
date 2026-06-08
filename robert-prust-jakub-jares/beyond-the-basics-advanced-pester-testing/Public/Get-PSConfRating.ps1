function Get-PSConfRating {
    <#
    .SYNOPSIS
        Gets ratings, optionally filtered by id or session id.

    .PARAMETER Id
        If specified, returns a single rating by its id.

    .PARAMETER SessionId
        If specified, returns only ratings for that session.

    .EXAMPLE
        Get-PSConfRating -Id R001

    .EXAMPLE
        Get-PSConfRating -SessionId S001

    .OUTPUTS
        PSConfRating
    #>
    [CmdletBinding()]
    [OutputType('PSConfRating')]
    param(
        [string] $Id,
        [string] $SessionId
    )

    if ($Id) {
        Invoke-PSConfApi -Path "/ratings/$Id" | ConvertTo-PSConfRating
    }
    else {
        $apiParams = @{ Path = '/ratings' }
        if ($SessionId) {
            $apiParams.Query = [ordered]@{ sessionId = $SessionId }
        }
        Invoke-PSConfApi @apiParams | ConvertTo-PSConfRating
    }
}
