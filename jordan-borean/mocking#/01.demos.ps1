#!/usr/bin/env pwsh
# Demo definitions for basic PSNetDetour mocking

Import-Module -Name PSNetDetour -ErrorAction Stop

Info {
    Title "Mocking# - .NET Method Detouring"

    Introduction "Learn how to intercept and mock .NET methods at runtime using PSNetDetour. Perfect for testing, debugging, and breaking the laws of reality!"

    KeyConcepts @("Concept 1")

    Summary "Summary"

    CommonPitfalls "Pitfalls here"
}

Demo "Intercept and log method calls" {
    Description "Spy on what methods are actually being called"

    Code {
        Use-NetDetourContext {
            New-NetDetourHook -Source { [System.IO.Path]::GetTempPath() } -Hook {
                Write-Host "🔍 Someone called GetTempPath()!" -ForegroundColor Cyan
                $result = $Detour.Invoke()
                Write-Host "   Returning: $result" -ForegroundColor Yellow
                return $result
            }

            $temp = [System.IO.Path]::GetTempPath()
            "Using temp path: $temp"
        }
    }
}

Demo "Modify method behavior - double the days" {
    Description "Intercept instance method and modify its behavior"

    Code {
        Use-NetDetourContext {
            New-NetDetourHook -Source { [DateTime].AddDays([double]) } -Hook {
                param($days)

                # Double the days!
                $result = $Detour.Invoke($days * 2)

                return $result
            }

            $date = [DateTime]::new(2026, 6, 1)
            $newDate = $date.AddDays(5)

            "Started with: 2026-06-01"
            "Asked for +5 days"
            "Got: $($newDate.ToString('yyyy-MM-dd'))"
        }
    }
}

Demo "Conditional mocking based on parameters" {
    Description "Only mock certain method calls based on input"

    Code {
        Use-NetDetourContext {
            New-NetDetourHook -Source { [System.IO.Path]::GetExtension([string]) } -Hook {
                param($path)

                if ($path -eq 'virus.exe') {
                    return ".definitely-not-malware"
                }

                return $Detour.Invoke($path)
            }

            "Normal file: " + [System.IO.Path]::GetExtension("document.pdf")
            "Script file: " + [System.IO.Path]::GetExtension("script.ps1")
            "Executable: " + [System.IO.Path]::GetExtension("virus.exe")
        }
    }
}

Demo "Simulating permission denied errors" {
    Description "Test error handling for access denied scenarios"

    Code {
        function Read-SecureFile {
            param([string]$Path)

            [System.IO.File]::ReadAllText($Path)
        }

        Use-NetDetourContext {
            New-NetDetourHook -Source { [System.IO.File]::ReadAllText([string]) } -Hook {
                param($path)

                throw [System.UnauthorizedAccessException]::new(
                    "All your bases are belong to us. Access to '$path' is denied."
                )
            }

            Read-SecureFile -Path "/etc/shadow"
        }
    }
}

Demo "Always lucky - mock Random.Next()" {
    Description "Rig the dice in your favor"

    Code {
        function vegas-mode {
            param($sbk)

            Use-NetDetourContext {
                New-NetDetourHook -Source { [Random].Next([int], [int]) } -Hook {
                    param($minValue, $maxValue)

                    return $maxValue - 1
                }

                & $sbk
            }
        }

        $rng = [Random]::new()

        "Real random numbers:"
        1..5 | ForEach-Object { $rng.Next(1, 7) }

        "`nAlways lucky 6s:"
        vegas-mode {
            1..5 | ForEach-Object { $rng.Next(1, 7) }
        }

        "`nReal randomness restored:"
        1..5 | ForEach-Object { $rng.Next(1, 7) }
    }
}

Demo "Schrödinger's boolean" {
    Description "That poor boolean can't decide if it's true or false"

    Code {
        Use-NetDetourContext {
            $script:flipFlop = $true

            New-NetDetourHook -Source { [bool].ToString() } -Hook {
                $script:flipFlop = -not $script:flipFlop
                return $script:flipFlop.ToString()
            }

            $value = $true

            "Observing a boolean value that is true:"
            1..4 | ForEach-Object {
                "  Observation $_`: $value"
            }

            "`n(Quantum mechanics has entered the chat)"
        }
    }
}

Demo "PSConfEU-2027 Location" {
    Description "Announcing the next PSConfEU location with a little help from PSNetDetour"

    Code {
        $locations = @("Berlin", "Paris", "London", "Rome", "Copenhagen", "Lisbon", "Barcelona",
            "Vienna", "Amsterdam", "Prague", "Dublin", "Stockholm", "Brisbane", "Budapest", "Zurich",
            "Warsaw", "Helsinki", "Oslo", "Brussels", "Athens")
        $type = (Get-Command Get-Random).ImplementingType.Assembly.GetType('Microsoft.PowerShell.Commands.PolymorphicRandomNumberGenerator')
        $meth = $type.GetMethod('Next', [type[]]@([int], [int]))

        Use-NetDetourContext {
            New-NetDetourHook -Method $meth -Hook {
                $locations.IndexOf("Brisbane")
            }

            $chosenId = Get-Random -Minimum 0 -Maximum $locations.Length
            $selection = $locations[$chosenId]
            "The next PSConfEU will be held in: $selection!"
        }
    }
}
