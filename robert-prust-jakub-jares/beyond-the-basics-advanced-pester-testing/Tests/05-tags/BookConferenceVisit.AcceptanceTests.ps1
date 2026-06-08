# Tags — run subsets of tests with -Tag / -ExcludeTag
#
# Try:
#   Invoke-Pester ./Tests -Tag Acceptance
#   Invoke-Pester ./Tests -ExcludeTag Slow
#
# Same thing via PesterConfiguration:
#   $config = New-PesterConfiguration
#   $config.Filter.Tag = 'Acceptance'
#   Invoke-Pester -Configuration $config
#
# Run only *.AcceptanceTests.ps1 files:
#   $config = New-PesterConfiguration
#   $config.Run.Path = './Tests'
#   $config.Run.TestExtension = '.AcceptanceTests.ps1'
#   Invoke-Pester -Configuration $config

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
    Import-Module "$PSScriptRoot/../../api/PSConfEUTestServer.psd1" -Force

    $port = 5058
    InModuleScope PSConfEU -Parameters @{ url = "http://localhost:$port" } {
        $script:PSConfApiBase = $url
    }

    Start-PSConfEUServer -Port $port
}

AfterAll {
    Stop-PSConfEUServer
}

Describe 'Book a conference visit' -Tag 'Acceptance', 'Slow' {

    It 'registers, picks sessions, and rates them' {
        $me = Register-PSConfAttendee -Name 'Robert' -Email 'robert@example.com' -Company 'Wortell'
        $me.Id | Should -Match '^A\d+'

        $picks = @(Get-PSConfSession -Track Testing -Day '2026-05-19')
        $picks.Count | Should -BeGreaterThan 0

        $r = Submit-PSConfRating -SessionId $picks[0].Id -Stars 5 -Comment 'Great!'
        $r.Stars | Should -Be 5
    }
}
