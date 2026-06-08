# Integration: real API, no mocks
# Same functions as Ch 3, but now we test against the real server.

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
    Import-Module "$PSScriptRoot/../../api/PSConfEUTestServer.psd1" -Force

    $port = 5055
    InModuleScope PSConfEU -Parameters @{ url = "http://localhost:$port" } {
        $script:PSConfApiBase = $url
    }

    Start-PSConfEUServer -Port $port
}

AfterAll {
    Stop-PSConfEUServer
}

Describe 'Get-PSConfSession (integration)' -Tag 'Acceptance' {

    It 'lists all sessions from the real API' {
        $all = @(Get-PSConfSession)
        $all.Count | Should -BeGreaterThan 10
        $all[0].PSObject.TypeNames[0] | Should -Be 'PSConfSession'
    }

    It 'filters by track' {
        $testing = @(Get-PSConfSession -Track Testing)
        $testing.Count | Should -BeGreaterThan 0
        $testing | ForEach-Object { $_.Track | Should -Be 'Testing' }
    }
}

Describe 'Submit and verify a rating (integration)' -Tag 'Acceptance' {

    It 'rating is persisted and can be retrieved from the API' {
        # TASK: Round-trip test — rate a session, then verify the rating was saved.
        #   1. Get a session with Get-PSConfSession (pick the first one)
        #   2. Submit a 5-star rating for it with Submit-PSConfRating, capture the result
        #   3. Use Get-PSConfRating -Id to retrieve it by the returned Id
        #   4. Verify the rating has the right Stars and SessionId
        # END TASK
    }
}
