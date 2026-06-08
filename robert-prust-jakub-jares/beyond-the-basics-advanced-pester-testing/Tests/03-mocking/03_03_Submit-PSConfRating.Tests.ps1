# Proving what was NOT called: Should -Invoke -Times 0

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

Describe 'Submit-PSConfRating' -Tag 'Unit' {

    It 'rejects invalid stars without calling the API' {
        Mock Invoke-PSConfApi -ModuleName PSConfEU { throw "GUARD: unexpected API call" }

        { Submit-PSConfRating -SessionId S001 -Stars 6 -Comment 'great' } |
            Should -Throw -ExpectedMessage '*Stars*'

        # TASK: Prove Invoke-PSConfApi was never called.

        # END TASK
    }
}
