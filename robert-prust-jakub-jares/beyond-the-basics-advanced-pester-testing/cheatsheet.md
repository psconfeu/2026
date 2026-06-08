# Pester Workshop Solutions Cheatsheet

1. `Tests/01-first-test/Test-PSConfRating.Tests.ps1` - valid rating tests

   ```powershell
   It 'accepts 2' {
       Test-PSConfRating -Stars 2 | Should -BeTrue
   }
   It 'accepts 3' {
       Test-PSConfRating -Stars 3 | Should -BeTrue
   }
   It 'accepts 4' {
       Test-PSConfRating -Stars 4 | Should -BeTrue
   }
   ```

2. `Tests/01-first-test/Test-PSConfRating.Tests.ps1` - invalid rating tests

   ```powershell
   It 'rejects zero' {
       Test-PSConfRating -Stars 0 | Should -BeFalse
   }
   It 'rejects too high' {
       Test-PSConfRating -Stars 6 | Should -BeFalse
   }
   It 'rejects negative' {
       Test-PSConfRating -Stars -1 | Should -BeFalse
   }
   It 'rejects text' {
       Test-PSConfRating -Stars 'abc' | Should -BeFalse
   }
   It 'rejects null' {
       Test-PSConfRating -Stars $null | Should -BeFalse
   }
   It 'rejects fractions' {
       Test-PSConfRating -Stars 3.5 | Should -BeFalse
   }
   ```

3. `Tests/02-data-driven/02_01_Test-PSConfRating.DataDriven.Tests.ps1` - valid data rows

   ```powershell
   @{ Stars = 2 }
   @{ Stars = 3 }
   @{ Stars = 4 }
   ```

4. `Tests/02-data-driven/02_01_Test-PSConfRating.DataDriven.Tests.ps1` - invalid data rows

   ```powershell
   @{ Name = 'zero'; Stars = 0 }
   @{ Name = 'negative'; Stars = -1 }
   @{ Name = 'text'; Stars = 'abc' }
   @{ Name = 'null'; Stars = $null }
   @{ Name = 'fraction'; Stars = 3.5 }
   ```

5. `Tests/02-data-driven/02_02_BeforeDiscovery.Tests.ps1` - discovery-time data

   ```powershell
   BeforeDiscovery {
       $ratings = @(
           @{ Stars = 1; Expected = $true }
           @{ Stars = 3; Expected = $true }
           @{ Stars = 6; Expected = $false }
           @{ Stars = 0; Expected = $false }
       )
   }
   ```

6. `Tests/03-mocking/03_01_Get-PSConfSession.Tests.ps1` - guard mock

   ```powershell
   Mock Invoke-PSConfApi -ModuleName PSConfEU {
       throw 'GUARD: unexpected API call'
   }
   ```

7. `Tests/03-mocking/03_01_Get-PSConfSession.Tests.ps1` - fake sessions mock

   ```powershell
   Mock Invoke-PSConfApi -ModuleName PSConfEU {
       @(
           @{ title = 'Pester Basics'; track = 'Testing'; startTime = '2026-05-19T09:00:00Z'; endTime = '2026-05-19T09:45:00Z' }
           @{ title = 'Advanced Mocking'; track = 'Testing'; startTime = '2026-05-19T10:00:00Z'; endTime = '2026-05-19T10:45:00Z' }
       )
   }
   ```

8. `Tests/03-mocking/03_01_Get-PSConfSession.Tests.ps1` - verify the API track filter

   ```powershell
   Should -Invoke Invoke-PSConfApi -ModuleName PSConfEU -Times 1 -Exactly -ParameterFilter {
       $Query.track -eq 'Testing'
   }
   ```

9. `Tests/03-mocking/03_02_Get-PSConfSession.Tests.ps1` - freeze time with `Mock Get-Date`

   ```powershell
   Mock Get-Date -ModuleName PSConfEU {
       [datetime]::new(2025, 6, 24, 6, 0, 0, [DateTimeKind]::Utc)
   }
   ```

10. `Tests/03-mocking/03_03_Submit-PSConfRating.Tests.ps1` - verify the API was not called

    ```powershell
    Should -Invoke Invoke-PSConfApi -ModuleName PSConfEU -Times 0 -Exactly
    ```

11. `Tests/04-integration/Get-PSConfSession.Integration.Tests.ps1` - rating round trip

    ```powershell
    $session = Get-PSConfSession | Select-Object -First 1
    $created = Submit-PSConfRating -SessionId $session.Id -Stars 5
    $saved = Get-PSConfRating -Id $created.Id

    $saved.Id | Should -Be $created.Id
    $saved.Stars | Should -Be 5
    $saved.SessionId | Should -Be $session.Id
    ```
