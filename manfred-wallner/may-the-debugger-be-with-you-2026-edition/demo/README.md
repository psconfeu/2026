# May the Debugger Be with You — 2026 Edition

## Follow-Along Demo

### Requirements

Participants should have PowerShell and VS Code installed on their machines (preferably PowerShell 7+).

Install the [PowerShell extension for VS Code](vscode:extension/ms-vscode.PowerShell).
For more information, see the [VS Code PowerShell docs](https://code.visualstudio.com/docs/languages/powershell).

### Examples

| #   | File                         | Topic                                                  |
| --- | ---------------------------- | ------------------------------------------------------ |
| 0   | `ex_0_rng.ps1`               | Breakpoints & `Wait-Debugger` basics                   |
| 1   | `ex_1_mysteryAPI.ps1`        | Debugging a REST API client against a live Pode server |
| 2   | `ex_2_fortune_container.ps1` | Debugging PowerShell running inside a Docker container |
| 3   | `ex_3_anomaly_scanner.ps1`   | Crash dumps with `trap` error handlers                 |

### Setup

**Examples 0 and 3** only require `pwsh` — no extra dependencies.

**Example 1** requires [Pode](https://github.com/Badgerati/Pode). Install it once:

```pwsh
Install-Module Pode
```

Then start the Mystery Shack API server before running the example:

```pwsh
pwsh pode/mystery-shack/mystery_shack_pode.ps1
```

**Example 2** requires Docker. Please pull the base image during the first part or the break, so we don't all download it at the same time:

```pwsh
docker pull mcr.microsoft.com/powershell:7.5-ubuntu-22.04
```
