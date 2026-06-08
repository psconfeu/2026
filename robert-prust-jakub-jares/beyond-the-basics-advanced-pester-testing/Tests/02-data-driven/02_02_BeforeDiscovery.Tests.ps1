# TASK 2b: Why BeforeDiscovery exists
#
# This works. During the demo, change BeforeDiscovery → BeforeAll
# and run again to show the failure. Then change it back.

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

BeforeDiscovery {
    $ratings = @(
        @{ Stars = 1; Expected = $true }
        @{ Stars = 3; Expected = $true }
        @{ Stars = 6; Expected = $false }
        @{ Stars = 0; Expected = $false }
    )
}

Describe 'Test-PSConfRating' -Tag 'Unit' {
    It 'rating <Stars> returns <Expected>' -ForEach $ratings {
        Test-PSConfRating -Stars $Stars | Should -Be $Expected
    }
}
