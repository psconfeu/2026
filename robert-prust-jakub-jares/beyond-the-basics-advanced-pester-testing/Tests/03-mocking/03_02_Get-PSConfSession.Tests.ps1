# Mocking built-in commands: freezing time with Mock Get-Date

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

Describe 'Get-PSConfSession — TimeUntilSession' -Tag 'Unit' {

    BeforeEach {
        # Pester Basics at PSConfEU 2025, Malmö — time doesn't stand still!
        Mock Invoke-PSConfApi -ModuleName PSConfEU {
            @(@{
                title     = 'Teach yourself Pester'
                track     = 'Testing'
                startTime = '2025-06-24T09:00:00+02:00'
                endTime   = '2025-06-24T10:30:00+02:00'
            })
        }
    }

    # This passed at last year's conference. It doesn't anymore.
    It 'session has not started yet' {
        # TASK: Mock Get-Date so the session is still 1 hour away.

        # END TASK

        $results = Get-PSConfSession -Track Testing
        $results[0].TimeUntilSession.TotalHours | Should -Be 1
    }
}
