function Test-PSConfRating {
    <#
    .SYNOPSIS
        True if the value is an integer between 1 and 5 inclusive.

    .DESCRIPTION
        Pure validator. Returns `$true` only when the input is a real `[int]`
        in the closed range [1..5]. Anything else — including `$null`, strings,
        fractions, booleans (after conversion), or out-of-range ints — returns
        `$false`.

        Used by `Submit-PSConfRating` for client-side checks before hitting the
        API, and as the workshop's chapter-1 pure-function example.

    .PARAMETER Stars
        The value to validate. Untyped so the function can decide for itself
        what's valid (rather than the parameter binder throwing on type
        coercion).

    .EXAMPLE
        Test-PSConfRating -Stars 5

        Returns $true.

    .EXAMPLE
        1..6 | ForEach-Object { "{0} -> {1}" -f $_, (Test-PSConfRating -Stars $_) }

        Visualises the validation table:
            1 -> True
            2 -> True
            3 -> True
            4 -> True
            5 -> True
            6 -> False

    .EXAMPLE
        if (-not (Test-PSConfRating -Stars $userInput)) {
            throw "Stars must be 1-5"
        }

        Guard at the top of a function that takes user input.

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Stars
    )
    if ($null -eq $Stars) { return $false }
    if ($Stars -isnot [int]) { return $false }
    return ($Stars -ge 1) -and ($Stars -le 5)
}
