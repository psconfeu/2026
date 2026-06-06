---
background: Gray0
foreground: Gray11
borderStyle: None
h1: super-mario-brothers-3-all-stars
h2: negative-quinpix
h3: 04B_08__
h1Color: Gray11
h2Color: Gray11
h3Color: Gray11
pagination: true
paginationStyle: fraction
---
<!-- h3: super-mario-brothers-3-all-stars -->

### Watch Your Step!
*Building Long-Running Scripts That Don't Trip Over Themselves*  

---

## This Talk Is For You If...

---

### You write multi-step automation

* Deployments
* Migrations
* Data collection
* Health checks

---

### What about one-liner writers?

* Stick around! The patterns scales down!

---
<!-- h2: 04B_19__ -->

## <red>The Problem</red>

---

### You started a script...

---

### ...3 hours and 28 minutes ago...

---

### ... and the unexpected happens:
* Construction equipment "discovers" your network run.
* Your terminal crashes for no apparent reason.
* An update reboots your laptop without warning.
* OpenClaw reboots your laptop without warning.


---

### The only thing you know for certain:

---
<!-- h2: 04B_19__ -->

## <red>You Are Starting Over.</red>

---

### Ever happened to you?
```
Raise your hand!
```

---

### The Cost
Not just inconvenience.

---

### Time
Re-running a 6-hour job because step 4 of 5 failed

---

### Money
Cloud provisioning steps that bill per API call

---

### Correctness
non-idempotent steps that partially succeeded

---

### Most Importantly...

---
<!-- h2: 04B_19__ -->

## <red>Trust</red>

---

## How did we get here?

---

### Scripts Grow Up

PowerShell scripts don't start long-running and complex.

* They start as one-liners
* Get duct-taped together over time
* Accumulate implicit ordering dependencies
* Nobody documents the assumptions
* Eventually: 5000 lines of fragility

---

### Fragility Sneaks Up On You

* Rolling your own resume logic is non-trivial
* Nobody does it for a "quick automation task"
* When script _usually_ works, resilience feels premature

---
<!-- h2: 04B_19__ -->

## <red>Typical Solutions</red>

---

### -Skip Switches

```powershell
.\Deploy.ps1 -SkipInfraSetup -SkipDatabaseMigration
```

* Works great! Until you forget which steps ran
* <yellow>You</yellow> are the state store
* Scales to ~3 switches before chaos
* Breaks when skipped steps produce data for other steps
* Logic gets complex _quickly_

---

### Multiple Scripts

```
Step1-GatherData.ps1
Step2-ProcessData.ps1
Step3-AnalyseData.ps1
Step4-GenerateReport.ps1
```

* Data passing between scripts is <yellow>your</yellow> problem
* Numerical order is not a contract
* Debugging is significantly harder

---
<!-- autoAdvance: 1400 -->

### Babysitting

* <yellow>You</yellow> sit there and watch it run
* <yellow>You</yellow> re-run if it fails
* <yellow>You</yellow> take notes* on where it stopped

* <red>*Hopefully</red>

---

### Babysitting

- <yellow>You</yellow> sit there and watch it run
- <yellow>You</yellow> re-run if it fails
- <yellow>You</yellow> take notes* on where it stopped

- <red>*Hopefully</red>

---

### Babysitting

This is a solution many people are using.


---

### Babysitting

It is NOT automation.


---

### Babysitting

It is babysitting _the very thing_ that was supposed to _eliminate babysitting_


---

### What All Three Have In Common

None of them give the <red>script</red> a brain.

- The <red>script</red> is <deeppink1>stateless</deeppink1>
- <yellow>You</yellow> are <lightskyblue1>the state</lightskyblue1>
- <yellow>Your notes</yellow> are <lightskyblue1>the state</lightskyblue1>
- That <yellow>README</yellow> you wrote six months ago is <lightskyblue1>the state</lightskyblue1>

---

### The Gap

What those workarounds actually do?

* Route <red>around</red> the problem

---

### The Gap

- `-Skip` switches
- Numbered script files
- Monitoring the terminal at midnight

All just you doing manually...
* what the script should be doing itself.
---

### The script we built to free us from babysitting...

---

### Needs a sitter.

![sob](sob.png)

---

### But what about PowerShell Workflows?

---
<!-- h3: 04B_19__ -->

### <red>DROPPED</red>

from PowerShell Core

---
<!-- h3: 04B_19__ -->

### DROPPED

and also required deep Windows Workflow Foundation knowledge for troubleshooting?

---

## My Solution:

---

### Give Your Scripts A Brain

---

### <magenta>(It's not AI)</magenta>

---

### It's Stepper!

Stepper provides things a resumable script needs:
```
Discrete Checkpoints
```

---

### It's Stepper!

Stepper provides things a resumable script needs:
```
Persistent State
```

---

### It's Stepper!

Stepper provides things a resumable script needs:
```
Resume/Retry Logic
```

---

### Discrete Checkpoints
| Step |
|-|
| A discrete, observable unit of work |
| with a clear beginning and end |


---

### Persistent state

| .stepper File |
|-|
| Just a CliXml file stored beside your script |
| Holds only the data you want to store: $Stepper.<variable> |
| Survives crashes, restarts, excavators |

---

### Resume/Retry Logic
| Resume | Retry |
|-|-|
| Skip already-completed work on re-run | Exponential backoff to prevent overloading an overworked API (or coworker) |

---

### The Mental Model

Run 1: 
* Step 1 <green>✓</green> Collection complete
* Step 2 <green>✓</green> Processing complete
* Step 3 <red>✗ CRASH</red>
* <red>OH NO :(</red> 

---

### The Mental Model
Run 2:
- Step 1 <blue>-</blue> Data exists: <blue>SKIP!</blue>
- Step 2 <blue>-</blue> Processed: <blue>SKIP!</blue>
* Step 3 <green>✓</green> Analysis complete
* Step 4 <green>✓</green> Reports generated

---

### My Real-World Use Case

---

### Collect Data From Customer Site

---

### Build Analysis Environment

---

### Ingest Data

---

### Perform Initial Processing

---

### Send Report to Customer

---

### Wait For A Reply...

---
<!-- autoAdvance: 400 -->

### <Gray11>And Wait...</Gray11>

---
<!-- autoAdvance: 400 -->

### <Gray23>And Wait...</Gray23>

---
<!-- autoAdvance: 400 -->

### <Gray30>And Wait...</Gray30>

---
<!-- autoAdvance: 400 -->

### <Gray42>And Wait...</Gray42>

---
<!-- autoAdvance: 400 -->

### <Gray50>And Wait...</Gray50>

---
<!-- autoAdvance: 400 -->

### <Gray62>And Wait...</Gray62>

---
<!-- autoAdvance: 400 -->

### <Gray70>And Wait...</Gray70>

---
<!-- autoAdvance: 400 -->

### <Gray82>And Wait...</Gray82>

---
<!-- autoAdvance: 400 -->

### <Gray93>And Wait...</Gray93>

---

### <White> </White>

---

### Receive Marked Up Report

---

### Perform Secondary Processing

---

### Analyze Data

---

### Prepare Final Report

---

### Broken/Slow Spots:

* Analysis Environment Buildout
* Data Ingestion
* Customer Round-Trip

---

### Not New Ideas
- Extract, Transform, Load pipelines
- Database migrations
- Package managers

---

### <red>We're just applying them to scripts.</red>

---

### Basic Commands

| Command | What it does |
|---|---|
| New-Step {} | marks a resumable unit of work |

---

### Basic Commands

| Command | What it does |
|---|---|
| Stop-Stepper | cleans up state on successful completion |

---

### Basic Commands
```
That's it. Everything else is optional.
```

---

### Other Commands

| Command | What it does |
|---|---|
| New-StepperScript | Generates a Stepper script template w/ all required markup added |

---

### Other Commands

| Command | What it does |
|---|---|
| Test-StepperScript | Ensures your script has all the stuff it needs to get Stepped |

---

### Other Commands

| Command | What it does |
|---|---|
| Repair-StepperScript | Adds/restores markup needed for a full-featured Stepper script |

---

### Other Commands

| Command | What it does |
|---|---|
| ConvertTo-StepperScript | Automates the basic $variable => $Stepper.variable process |

---

## How it works

---

### First Run

* ` New-Step {} `: calls Test-StepperScript
* ` Test-StepperScript `: finds script problems to feed into Repair-StepperScript
* ` Repair-StepperScript `: fixes problems identified by Test-StepperScript
* ` ConvertTo-StepperScript `: interactive guide to converting variables
* If Stepper modifies the script, it will ask you to restart the process.
* Once a script meets Stepper requirements, normal script execution occurs.

---

### Subsequent Runs

When the first ` New-Step {} ` starts, it checks if a
.stepper file exists.

If a .stepper file is found, ` New-Step {} ` does the following:
* Loads saved data from .stepper file
* Compares the script's current hash against its saved hash
* Prompts the user if they want to resume/start over

---

### Subsequent Runs

` New-Step {} ` (end): Saves all $Stepper.<variables> to .stepper file.

---
<!-- h3: 04B_19__ -->

### <red>Start-Demo</red>
(finally)

---

### Install

```powershell
Install-Module -Name Stepper -Scope CurrentUser -Force
```

PS 5.1+, cross-platform.

---

## Generalize The Pattern

---

### Generalize The Pattern

```
Identify Checkpoints

Where are the logical units of work?
```

---

### Generalize The Pattern

```
Externalize State

Use disk, not $localVariable
```
---

### Generalize The Pattern

```
Make Steps Idempotent

A step you can safely re-run is a step you don't fear
```

---

### Generalize The Pattern

```
Track Position AND Data

Know which steps completed
```

---

### The Pattern is the Point.

---

### <red>The Tool is just the Tool.</red>

---

## Wrap Up

---

### Summary

* Long-running automation is fragile
* Workarounds outsource state management to humans
* Resillience means checkpoints + state + resume/retry logic
* Stepper gets you there in ~10 minutes of wrapper work
* The patterns apply everywhere

---

### This Week

* Pick one script that runs more than 5 minutes
* Identify 2 or more checkpoints
* Wrap the first logical Step in `New-Step {}` block

---

### Resources
https://jakehildreth.com
https://stepper.jakehildreth.com
