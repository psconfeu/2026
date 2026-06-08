# PSConfEU Workshop

PowerShell client for the PSConfEU Conference API — the worked example for the **Advanced Pester Workshop** at PSConfEU 2026.

## What's in here

- `PSConfEU.psd1` / `PSConfEU.psm1` — the module itself
- `Public/`, `Private/` — module source
- `Tests/` — Pester 5 tests, one folder per chapter
- `api/` — a tiny PowerShell `HttpListener` mock API
- `build/Invoke-Tests.ps1` — single test runner
- `.github/workflows/` — GitHub Actions CI examples

## Run tests

```powershell
pwsh ./build/Invoke-Tests.ps1 -Tag Unit
```

## Workshop chapter map

| # | Chapter | Folder |
|---|---------|--------|
| 1 | First Pester test | `Tests/01-first-test/` |
| 2 | Data-driven tests | `Tests/02-data-driven/` |
| 3 | Mocking the API | `Tests/03-mocking/` |
| 4 | Advanced mocking | `Tests/04-advanced-mocking/` |
| 5 | Integration tests | `Tests/05-integration/` |
| 6 | Acceptance & tags | `Tests/06-acceptance-and-tags/` |
| 7 | CI | `.github/workflows/` (demo-led, no test folder) |
