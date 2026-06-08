# TASK 2a: Data-driven — same function, now with -ForEach
#
# Add rows to each -ForEach array:
#   valid:   2, 3, 4
#   invalid: 0, -1, 'abc', $null, 3.5 (give each a descriptive Name)

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

Describe 'Test-PSConfRating (data-driven)' -Tag 'Unit' {

    Context 'valid ratings' {
        It 'accepts <Stars>' -ForEach @(
            @{ Stars = 1 }
            @{ Stars = 5 }

            # TASK: Add rows for Stars 2, 3, and 4.
            # END TASK
        ) {
            Test-PSConfRating -Stars $Stars | Should -BeTrue
        }
    }

    Context 'invalid ratings' {
        It 'rejects <Name> (<Stars>)' -ForEach @(
            @{ Name = 'too high'; Stars = 6 }

            # TASK: Add rows for: 0, -1, 'abc', $null, 3.5
            # Give each a descriptive Name.
            # END TASK
        ) {
            Test-PSConfRating -Stars $Stars | Should -BeFalse
        }
    }
}
