# First mocking demo: -ModuleName, Mock, Should -Invoke, guard mock
#
# Invoke-PSConfApi is private — Mock needs -ModuleName PSConfEU
# to replace it inside the module.

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

Describe 'Get-PSConfSession' -Tag 'Unit' {

    BeforeEach {
        # TASK: Add a guard mock for Invoke-PSConfApi — if any test
        # calls the API without a specific mock, throw immediately.

        # END TASK
    }

    It 'returns sessions for the given track' {
        # TASK: Mock Invoke-PSConfApi to return fake sessions.
        # Hint: the function is private — you need -ModuleName PSConfEU.
        # Mock should return:
        # @(
        #     @{ title = 'Pester Basics'; track = 'Testing'; startTime = '2026-05-19T09:00:00Z'; endTime = '2026-05-19T09:45:00Z' }
        #     @{ title = 'Advanced Mocking'; track = 'Testing'; startTime = '2026-05-19T10:00:00Z'; endTime = '2026-05-19T10:45:00Z' }
        # )

        # END TASK

        $results = Get-PSConfSession -Track Testing
        $results | Should -HaveCount 2
        $results[0].Title | Should -Be 'Pester Basics'
    }

    It 'passes track filter to the API' {
        Mock Invoke-PSConfApi -ModuleName PSConfEU { @() } -ParameterFilter {
            $Query.track -eq 'Testing'
        }

        Get-PSConfSession -Track Testing | Out-Null

        # TASK: Assert that Invoke-PSConfApi was called exactly once
        # with the track filter. Use Should -Invoke.

        # END TASK
    }
}
