function Get-PSConfApiBase {
    <#
    .SYNOPSIS
        Resolves the API base URL: env-var override or sane default.

    .DESCRIPTION
        Returns $env:PSConf_API_URL if set, otherwise `http://localhost:5000`.

        Called once during module import (from PSConfEU.psm1), and the result
        is cached into `$script:PSConfApiBase`. Tests override the script-scope
        variable directly inside `InModuleScope`, which is why this function
        isn't called every request.

        Private — module-internal. Not exported.

    .EXAMPLE
        Get-PSConfApiBase

        Returns the configured base, e.g. 'http://localhost:5000'.

    .EXAMPLE
        $env:PSConf_API_URL = 'http://api:5000'
        Get-PSConfApiBase

        Returns 'http://api:5000'. This is how the test container reaches the
        compose api service.

    .EXAMPLE
        # Inside a test that needs to repoint at a fresh API:
        InModuleScope PSConfEU {
            $script:PSConfApiBase = 'http://localhost:5055'
        }

        Tests bypass this function entirely by writing the cached variable.

    .OUTPUTS
        System.String — the API base URL, no trailing slash assumed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    if ($env:PSConf_API_URL) { return $env:PSConf_API_URL }
    return 'http://localhost:5000'
}
