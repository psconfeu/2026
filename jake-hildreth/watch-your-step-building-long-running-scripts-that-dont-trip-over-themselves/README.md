# Watch Your Step! Building Long-Running Scripts That Don't Trip Over Themselves

## How To View The Slides

```powershell
Install-Module -Name Deck -Scope CurrentUser -Force
Show-Deck -Path https://raw.githubusercontent.com/psconfeu/2026/refs/heads/main/jake-hildreth/watch-your-step-building-long-running-scripts-that-dont-trip-over-themselves/watch-your-step.md
```

## Recreate The Demo Yourself!
### Install Prereqs
```powershell
Set-Location ./StepperDemo
Get-ChildItem ./private/*.ps1 | ForEach-Object { . $_.FullName }
if ($isMacOs) { brew install mono-libgdiplus } # used by ImportExcel
Install-Module -Name Stepper -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser
```

### The Main Event
* [`demo1.ps1`](StepperDemo/demo1.ps1):
  * Run `./demo1.ps1` and simulate a crash by pressing Ctrl+C during the "Gathering Personal Storage" step.
  * Run `./demo1.ps1` again and see it starts over from the beginning.
  * Wrap the first two lines in `New-Step { <code> }`
  * Run `./demo1.ps1` and take the default option for everything. Repeat until `./demo1.ps1` operates like a normal script. Notice that each time the script is modified, a backup is made.
  * Simulate a crash by pressing Ctrl+C during the "Gathering Personal Storage" Step.
  * Take a moment to check out `./demo1.ps1.stepper`, a CliXml file which contains info about the state of `demo1.ps1`.
  * Run `./demo1.ps1` again and get prompted to Resume or Start Over. Try "Resume" and notice the first two Steps are skipped!
* [`demo2.ps1`](StepperDemo/demo2.ps1):
  * Run `./demo2.ps1` and see it fail in Step 3.
  * Change line 37 to `New-Step -Retry -RetryInterval 2 -MaxRetries 5 {`, then run `./demo2.ps1` again.
  * Notice Step 3 retries the process with exponential backoff. 
* [`demo3.ps1`](StepperDemo/demo3.ps1):
  * Change line 18 to `New-Step -Name 'Get New Users' {`
  * Change line 24 to `New-Step 'Create Storage for New Users' {`
  * Run `./demo3.ps1` and press Ctrl+C during the "Gathering Personal Storage" Step.
  * Take a look at `./demo3.ps1.stepper.log`. Stepper gives you logging for free!
  * Change line 30 to `New-Step -NoLog {`, then run `./demo3.ps1` again. Stepper will ask you how you want to handle logging now. Choose `s` to skip logging for the third Step.
  * Take a look at `./demo3.ps1.stepper.log` and notice Step 3 was not logged. Very useful for Steps that contain secrets or very noisy Steps.
* [`demo4.ps1`](StepperDemo/demo4.ps1):
  * Add a new line at line 22: `if ($null -eq $Stepper.NewUsers) { exit }`
  * Run `./demo4.ps1`. Stepper will prompt you what to do with this "unmanaged" code. Choose `m` to mark the code as expected. This line will run every time script runs, regardless of previous runs.
* [`demo5.ps1`](StepperDemo/demo5.ps1): Play with the other commands!

## Abstract

We've all been there. It's 11pm, you're running a 45-minute deployment script, and it fails at step 37 of 42. Cool. Cool cool cool. Now you get to start over. Or worse, you're not sure where it failed, so you spend 20 minutes poking around before you dare re-run anything.

Long-running automation is fragile. Networks drop. Systems reboot. Someone presses Ctrl+C. Your toddler walks in and demands breakfast. Reality happens.

I got tired of this, so I built Stepper: a small PowerShell module that lets you break scripts into discrete steps that automatically save their progress. When something goes wrong (or life happens), just run it again. It picks up where it left off.

It's basically a really simple PowerShell Workflow that actually works in PS7+!

In this session, I'll show you how to structure scripts as resumable steps, persist state across interruptions, and build configuration-driven automation that doesn't make you want to mass-delete your repo. We'll live-code an example, kill it mid-run on purpose, and watch it recover like nothing happened.

You don't have to use Stepper to get something out of this talk. The patterns apply whether you're using my module or rolling your own. If you build deployments, migrations, health checks, or any multi-step automation, you'll leave with ideas you can use immediately. Stop restarting from scratch and start building scripts that remember where they were.
