# Schedule validation: JSON import, nested -ForEach, sub-templates

$PesterPreference = [PesterConfiguration]@{ Output = @{ Verbosity = 'Detailed' } }

BeforeAll {
    Import-Module "$PSScriptRoot/../../PSConfEU.psd1" -Force
}

BeforeDiscovery {
    $all = Get-Content "$PSScriptRoot/Fixtures/sessions.json" -Raw |
        ConvertFrom-Json

    $script:tracks = $all | Group-Object Track | ForEach-Object {
        @{ Track = $_.Name; Sessions = @($_.Group) }
    }
}

Describe 'Conference schedule' -Tag 'Unit' {

    Context 'Track <Track>' -ForEach $tracks {

        It '<_.Title> — has a title under 100 characters' -ForEach $Sessions {
            $_.Title | Should -Not -BeNullOrEmpty
            $_.Title.Length | Should -BeLessOrEqual 100
        }

        It '<_.Title> — has a description' -ForEach $Sessions {
            $_.Description | Should -Not -BeNullOrEmpty
        }

        It '<_.Title> — spells PowerShell correctly' -ForEach $Sessions {
            $_.Description | Should -Not -MatchExactly '\bPowershell\b' -Because 'PowerShell has a capital S'
        }

        It 'no overlapping sessions' {
            $conflicts = Find-PSConfConflict -Session $Sessions
            $conflicts | Should -BeNullOrEmpty
        }
    }
}
