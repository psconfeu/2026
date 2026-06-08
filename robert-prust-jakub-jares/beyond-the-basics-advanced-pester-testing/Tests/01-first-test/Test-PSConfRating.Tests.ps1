# TASK 1: Your first Pester test
#
# Add the missing It blocks:
#   valid:   2, 3, 4        → Should -BeTrue
#   invalid: 0, 6, -1, 'abc', $null, 3.5 → Should -BeFalse

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

Describe 'Test-PSConfRating' -Tag 'Unit' {

    Context 'valid ratings' {
        It 'accepts 1' {
            Test-PSConfRating -Stars 1 | Should -BeTrue
        }
        It 'accepts 5' {
            Test-PSConfRating -Stars 5 | Should -BeTrue
        }

        # TASK: Add It blocks for stars 2, 3, and 4.
        # END TASK
    }

    Context 'invalid ratings' {
        # TASK: Add It blocks for: 0, 6, -1, 'abc', $null, 3.5
        #   It 'rejects <description>' { Test-PSConfRating -Stars <value> | Should -BeFalse }
        # END TASK
    }
}
