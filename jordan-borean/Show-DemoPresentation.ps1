#!/usr/bin/env pwsh

using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Runspaces
using namespace System.Text

#Requires -Module PwshSpectreConsole
#Requires -Module TextMate

<#
.SYNOPSIS
A script used for my demos in PSConfEU 2026.

.DESCRIPTION
This script defines a simple framework for creating interactive PowerShell demos with formatted output.
It allows you to define demo steps with setup, code, and teardown blocks, and captures PowerShell code output with ANSI color support.
The presentation can include pre/post pages with custom content and navigation controls.

See the *.demos.ps1 files for more details on how to structure the demos.

.PARAMETER DemoPath
The directory path that contains *.demos.ps1 file(s) to use as the demos.

.PARAMETER StartAt
The index of the demo to start at (default is 0 for the first demo and title page).

.PARAMETER LightMode
If specified, uses a light color theme for better visibility in light terminal themes.
By default, a dark theme is used.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DemoPath,

    [Parameter()]
    [int]$StartAt = 0,

    [Parameter()]
    [switch]$LightMode
)

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Management.Automation.Runspaces;
using System.Security;
using System.Text;

namespace Show.DemoPresentation;

public class CapturingHost : PSHost
{
    private readonly CapturingHostUI HostUI;

    public CapturingHost()
    {
        HostUI = new CapturingHostUI();
    }

    public override CultureInfo CurrentCulture => CultureInfo.InvariantCulture;

    public override CultureInfo CurrentUICulture => CultureInfo.InvariantCulture;

    public override Guid InstanceId => Guid.NewGuid();

    public override string Name => "CapturingHost";

    public override PSHostUserInterface UI => HostUI;

    public override Version Version => new Version("1.2.3");

    public override void EnterNestedPrompt()
    { }

    public override void ExitNestedPrompt()
    { }

    public override void NotifyBeginApplication()
    { }

    public override void NotifyEndApplication()
    { }

    public override void SetShouldExit(int exitCode)
    { }
}

public class CapturingHostUI : PSHostUserInterface
{
    private readonly StringBuilder _callHistory = new StringBuilder();

    public CapturingHostUI()
    { }

    public string CallHistory => _callHistory.ToString();

    public override PSHostRawUserInterface RawUI => null;

    public override Dictionary<string, PSObject> Prompt(string caption, string message, Collection<FieldDescription> descriptions)
    {
        throw new NotImplementedException();
    }

    public override int PromptForChoice(string caption, string message, Collection<ChoiceDescription> choices, int defaultChoice)
    {
        throw new NotImplementedException();
    }

    public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options)
    {
        throw new NotImplementedException();
    }

    public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
    {
        throw new NotImplementedException();
    }

    public override string ReadLine()
    {
        throw new NotImplementedException();
    }

    public override SecureString ReadLineAsSecureString()
    {
        throw new NotImplementedException();
    }

    public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
    {
        int fgCode = ConsoleColorToAnsiCode(foregroundColor, false);
        int bgCode = ConsoleColorToAnsiCode(backgroundColor, true);

        _callHistory.Append($"\x1B[{fgCode};{bgCode}m{value}\x1B[0m");
    }

    public override void Write(string value)
    {
        _callHistory.Append(value);
    }

    public override void WriteDebugLine(string message)
    {
        _callHistory.AppendLine($"\x1B[33mDEBUG: {message}\x1B[0m");
    }

    public override void WriteErrorLine(string value)
    {
        _callHistory.AppendLine($"\x1B[31m{value}\x1B[0m");
    }

    public override void WriteLine(string value)
    {
        _callHistory.AppendLine(value);
    }

    public override void WriteProgress(long sourceId, ProgressRecord record)
    { }

    public override void WriteVerboseLine(string message)
    {
        _callHistory.AppendLine($"\x1B[33mVERBOSE: {message}\x1B[0m");
    }

    public override void WriteWarningLine(string message)
    {
        _callHistory.AppendLine($"\x1B[33mWARNING: {message}\x1B[0m");
    }

    private static int ConsoleColorToAnsiCode(ConsoleColor color, bool isBackground)
    {
        int baseCode = isBackground ? 40 : 30;

        int colorCode = color switch
        {
            ConsoleColor.Black => 0,
            ConsoleColor.DarkRed => 1,
            ConsoleColor.DarkGreen => 2,
            ConsoleColor.DarkYellow => 3,
            ConsoleColor.DarkBlue => 4,
            ConsoleColor.DarkMagenta => 5,
            ConsoleColor.DarkCyan => 6,
            ConsoleColor.Gray => 7,
            ConsoleColor.DarkGray => 60,  // Bright black
            ConsoleColor.Red => 61,       // Bright red
            ConsoleColor.Green => 62,     // Bright green
            ConsoleColor.Yellow => 63,    // Bright yellow
            ConsoleColor.Blue => 64,      // Bright blue
            ConsoleColor.Magenta => 65,   // Bright magenta
            ConsoleColor.Cyan => 66,      // Bright cyan
            ConsoleColor.White => 67,     // Bright white
            _ => 7  // Default to gray
        };

        return baseCode + colorCode;
    }
}
'@

function Remove-CodeIndentation {
    <#
    .SYNOPSIS
        Normalizes code indentation by removing common leading whitespace
    #>
    param(
        [string]$Code
    )

    $lines = $Code -split "`r?`n"

    # Find the minimum indentation from the first non-empty line
    $firstNonEmpty = $lines | Where-Object { $_ -match '\S' } | Select-Object -First 1
    if ($null -eq $firstNonEmpty) {
        return $Code
    }

    $firstNonEmpty -match '^(\s*)' | Out-Null
    $baseIndentLength = $Matches[1].Length

    # Remove base indentation from all lines
    $normalizedLines = foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            # Preserve empty lines
            ""
        } elseif ($line -match "^(\s{0,$baseIndentLength})(.*)$") {
            # Remove up to baseIndent spaces, but not more (for lines with less indent like here-strings)
            $lineIndent = $Matches[1].Length
            if ($lineIndent -ge $baseIndentLength) {
                $line.Substring($baseIndentLength)
            } else {
                # Line has less indentation than base - keep it as-is (relative to start)
                $Matches[2]
            }
        } else {
            $line
        }
    }

    return ($normalizedLines -join "`n").Trim()
}



function Demo {
    <#
    .SYNOPSIS
        Defines a demo with title and script blocks
    .EXAMPLE
        Demo "Direct Invocation" {
            Description "Shows how PowerShell executes a binary directly"
            Setup { }
            Code { .\test-app.exe --verbose }
            Teardown { }
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Definition
    )

    $script:currentDemoContext = @{
        Title        = Get-SpectreEscapedText $Name
        Description  = ""
        CodeString   = ""
        CodeBlock    = $null
        SetupBlock   = $null
        TeardownBlock = $null
    }

    # Execute the definition block to capture Description/Setup/Code/Teardown
    & $Definition

    # Add the completed demo to our collection
    [PSCustomObject]$script:currentDemoContext

    # Clear context
    $script:currentDemoContext = $null
}

function Description {
    <#
    .SYNOPSIS
        Sets the description for the current demo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text
    )

    if ($null -eq $script:currentDemoContext) {
        throw "Description must be called within a Demo block"
    }

    $script:currentDemoContext.Description = $Text
}

function Setup {
    <#
    .SYNOPSIS
        Defines setup code that runs before the demo (hidden from user)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )

    if ($null -eq $script:currentDemoContext) {
        throw "Setup must be called within a Demo block"
    }

    $script:currentDemoContext.SetupBlock = $ScriptBlock
}

function Code {
    <#
    .SYNOPSIS
        Defines the code to display and execute for the demo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )

    if ($null -eq $script:currentDemoContext) {
        throw "Code must be called within a Demo block"
    }

    # Store the script block and its normalized string representation
    $codeString = $ScriptBlock.ToString()
    $script:currentDemoContext.CodeString = Remove-CodeIndentation -Code $codeString
    $script:currentDemoContext.CodeBlock = $ScriptBlock
}

function Teardown {
    <#
    .SYNOPSIS
        Defines teardown code that runs after the demo (hidden from user)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )

    if ($null -eq $script:currentDemoContext) {
        throw "Teardown must be called within a Demo block"
    }

    $script:currentDemoContext.TeardownBlock = $ScriptBlock
}

function Info {
    <#
    .SYNOPSIS
        Defines info block with pre/post page content for a demo file
    .EXAMPLE
        Info {
            Title "My Topic"
            Introduction "What we'll cover..."
            KeyConcepts @("Concept 1", "Concept 2")
            Summary "What we learned..."
            CommonPitfalls "Common mistakes..."
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Definition
    )

    $script:currentInfoContext = @{
        Title = ""
        Introduction = ""
        KeyConcepts = @()
        Summary = ""
        CommonPitfalls = ""
    }

    # Execute the definition block to capture Title/Introduction/etc.
    & $Definition

    # Return the completed info object
    [PSCustomObject]$script:currentInfoContext

    # Clear context
    $script:currentInfoContext = $null
}

function Title {
    <#
    .SYNOPSIS
        Sets the title for the current info block
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text
    )

    if ($null -eq $script:currentInfoContext) {
        throw "Title must be called within an Info block"
    }

    $script:currentInfoContext.Title = $Text
}

function Introduction {
    <#
    .SYNOPSIS
        Sets the introduction text for the pre-page
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text
    )

    if ($null -eq $script:currentInfoContext) {
        throw "Introduction must be called within an Info block"
    }

    $script:currentInfoContext.Introduction = $Text
}

function KeyConcepts {
    <#
    .SYNOPSIS
        Sets the key concepts list for the pre-page
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Items
    )

    if ($null -eq $script:currentInfoContext) {
        throw "KeyConcepts must be called within an Info block"
    }

    $script:currentInfoContext.KeyConcepts = $Items
}

function Summary {
    <#
    .SYNOPSIS
        Sets the summary content for the post-page
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text
    )

    if ($null -eq $script:currentInfoContext) {
        throw "Summary must be called within an Info block"
    }

    # Don't escape - summary can contain formatted code blocks
    $script:currentInfoContext.Summary = $Text
}

function CommonPitfalls {
    <#
    .SYNOPSIS
        Sets the common pitfalls content for the post-page
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text
    )

    if ($null -eq $script:currentInfoContext) {
        throw "CommonPitfalls must be called within an Info block"
    }

    # Don't escape - can contain formatted code blocks
    $script:currentInfoContext.CommonPitfalls = $Text
}

function Invoke-InDemoRunspace {
    <#
    .SYNOPSIS
        Executes a script block in the demo runspace and captures output
    #>
    param(
        [Parameter(Mandatory)]
        [powershell]$PowerShell,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [switch]$ErrorOnly
    )

    $capturingHost = [Show.DemoPresentation.CapturingHost]::new()
    $psInvocationSettings = [PSInvocationSettings]@{
        Host = $capturingHost
    }

    $PowerShell.Commands.Clear()
    $PowerShell.Streams.ClearStreams()

    # We add the ScriptBlock in this special way to preserve the AST from where
    # it was parsed allowing us to show the file and line numbers in error
    # messages. We also strip the affinity from the ScriptBlock so it doesn't
    # try and access the session state outside of the runspace.
    $null = $PowerShell.AddScript({
        # Enable ANSI color output so Out-String preserves colors
        $PSStyle.OutputRendering = 'Ansi'

        ${function:<Demo>} = $args[0].Ast.GetScriptBlock()
    }).AddArgument($ScriptBlock)

    # We then execute that ScriptBlock as a command as it ensures there's no
    # extra wrapping in the error stack traces.
    $null = $PowerShell.AddStatement().AddCommand('<Demo>', $false)

    # Ensure all output becomes a string, adjust the width to handle our
    # indented output formatting.
    $null = $PowerShell.AddCommand('Out-String').AddParameter('Width', [Console]::BufferWidth - 4)

    # Invoke and capture all output
    try {
        $out = $PowerShell.Invoke($null, $psInvocationSettings)
        $hostOut = $capturingHost.UI.CallHistory
        if (-not $ErrorOnly) {
            $out

            if ($hostOut) {
                $hostOut
            }
        }

        # Error stream (red)
        if ($PowerShell.Streams.Error.Count -gt 0) {
            foreach ($err in $PowerShell.Streams.Error) {
                $stLines = if ($err.ScriptStackTrace) {
                    @($err.ScriptStackTrace -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
                } else {
                    "(No stack trace)"
                }
                "$($PSStyle.Foreground.BrightRed)Error: $err`nStack Trace:`n$stLines$($PSStyle.Reset)"
            }
        }
    } catch {
        $stLines = if ($_.ScriptStackTrace) {
            @($_.ScriptStackTrace -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
        } else {
            "(No stack trace)"
        }

        "$($PSStyle.Foreground.BrightRed)Error: $_`nStack Trace:`n$stLines$($PSStyle.Reset)"
    }
}

function Show-DemoFrame {
    param(
        [Parameter(Mandatory)]
        [object[]]$Demos,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter()]
        [bool]$HasExecuted = $false,

        [Parameter()]
        [string]$Output = "",

        [Parameter()]
        [int]$PageNumber = 0,

        [Parameter()]
        [int]$TotalPages = 0,

        [Parameter()]
        [string]$TopicTitle = "",

        [Parameter(Mandatory)]
        [hashtable]$ColorTheme
    )

    $demo = $Demos[$Index]

    Clear-Host

    Write-Host $Title -ForegroundColor $ColorTheme.TitleForeground

    # Use TopicTitle if provided, otherwise fall back to demo title
    $ruleTitle = if ($TopicTitle) { " $TopicTitle " } else { " $($demo.Title) " }
    $ruleParams = @{
        Title = $ruleTitle
        Color = $ColorTheme.RuleColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # Example header panel
    $headerPanelParams = @{
        Data   = Get-SpectreEscapedText $demo.Description
        Header = $demo.Title
        Expand = $true
        Color  = $ColorTheme.PanelColor
    }
    Format-SpectrePanel @headerPanelParams | Out-Host

    # Code section with syntax highlighting
    $extent = $demo.CodeBlock.Ast.Extent
    $codeTitle = if ($extent.File) {
        $fileName = Split-Path -Path $extent.File -Leaf
        " Code ($fileName) "
    } else {
        " Code "
    }

    $codeRuleParams = @{
        Title = $codeTitle
        Color = $ColorTheme.CodeRuleColor
    }
    Write-SpectreRule @codeRuleParams | Out-Host

    # Add line numbers to code like VSCode gutter
    $highlightedCode = $demo.CodeString | Format-PowerShell -Theme $ColorTheme.PowerShellTheme
    $codeLines = $highlightedCode -split "`r?`n"

    $startLine = $extent.StartLineNumber
    $endLine = $extent.EndLineNumber
    $maxDigits = $endLine.ToString().Length

    Write-Host ""
    for ($i = 0; $i -lt $codeLines.Count; $i++) {
        $lineNum = $startLine + $i + 1
        $paddedLineNum = $lineNum.ToString().PadLeft($maxDigits)
        Write-Host "  $($ColorTheme.LineNumberForeground)$paddedLineNum$($PSStyle.Reset)  $($codeLines[$i])"
    }
    Write-Host ""

    $outputRuleParams = @{
        Title = " Output "
        Color = $ColorTheme.OutputRuleColor
    }
    Write-SpectreRule @outputRuleParams | Out-Host

    # Status or output
    if (-not $HasExecuted) {
        Write-Host "`n ⏸  Press Enter to execute...`n" -ForegroundColor $ColorTheme.PromptForeground
    } else {
        # Add 2-space indent to each line of output
        $indentedOutput = ($Output -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
        Write-Host ""
        Write-Host $indentedOutput.TrimEnd()
        Write-Host ""
    }

    $separatorParams = @{
        Color = $ColorTheme.SeparatorColor
    }
    Write-SpectreRule @separatorParams | Out-Host

    # Navigation controls
    Write-Host "`n[Enter]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    if ($HasExecuted) {
        Write-Host " Re-run  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    } else {
        Write-Host " Run  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    }

    Write-Host "[N]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Next  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    Write-Host "[P]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Previous  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground

    if ($HasExecuted) {
        Write-Host "[C]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
        Write-Host " Clear  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    }

    Write-Host "[Q]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Quit  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground

    # Progress indicator - use page numbers if provided, otherwise fall back to demo index
    if ($PageNumber -gt 0 -and $TotalPages -gt 0) {
        Write-Host "[" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
        Write-Host "$PageNumber" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
        Write-Host "/" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
        Write-Host "$TotalPages" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
        Write-Host "]" -ForegroundColor $ColorTheme.ProgressTextForeground -NoNewline
    }
}

function Show-PrePage {
    param(
        [Parameter(Mandatory)]
        [string]$BannerContent,

        [Parameter(Mandatory)]
        [object]$Info,

        [Parameter(Mandatory)]
        [int]$PageNumber,

        [Parameter(Mandatory)]
        [int]$TotalPages,

        [Parameter(Mandatory)]
        [hashtable]$ColorTheme
    )

    Clear-Host

    # Banner (same as demos)
    Write-Host $BannerContent -ForegroundColor $ColorTheme.TitleForeground

    $ruleParams = @{
        Title = " $($Info.Title) "
        Color = $ColorTheme.RuleColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # Introduction section (no panel, just text)
    Write-Host ""
    $indentedIntro = ($Info.Introduction -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
    Write-Host $indentedIntro
    Write-Host ""

    # Key concepts if provided
    if ($Info.KeyConcepts -and $Info.KeyConcepts.Count -gt 0) {
        $conceptsRuleParams = @{
            Title = " Key Concepts "
            Color = $ColorTheme.PanelColor
        }
        Write-SpectreRule @conceptsRuleParams | Out-Host

        Write-Host ""
        $conceptsText = ($Info.KeyConcepts | ForEach-Object { "  • $_" }) -join "`n"
        Write-Host $conceptsText
        Write-Host ""
    }

    $ruleParams = @{
        Color = $ColorTheme.SeparatorColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # Navigation - no Enter key
    Write-Host "`n[N]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Next  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    Write-Host "[P]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Previous  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    Write-Host "[Q]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Quit  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground

    # Progress indicator
    Write-Host "[" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
    Write-Host "$PageNumber" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
    Write-Host "/" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
    Write-Host "$TotalPages" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
    Write-Host "]" -ForegroundColor $ColorTheme.ProgressTextForeground -NoNewline
}

function Show-PostPage {
    param(
        [Parameter(Mandatory)]
        [string]$BannerContent,

        [Parameter(Mandatory)]
        [object]$Info,

        [Parameter(Mandatory)]
        [int]$PageNumber,

        [Parameter(Mandatory)]
        [int]$TotalPages,

        [Parameter(Mandatory)]
        [hashtable]$ColorTheme
    )

    Clear-Host

    # Banner (same as demos)
    Write-Host $BannerContent -ForegroundColor $ColorTheme.TitleForeground

    $ruleParams = @{
        Title = " $($Info.Title) "
        Color = $ColorTheme.RuleColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # Summary section with rule
    $summaryRuleParams = @{
        Title = " Summary "
        Color = $ColorTheme.PanelColor
    }
    Write-SpectreRule @summaryRuleParams | Out-Host

    # Write summary content directly (preserves ANSI codes)
    $indentedContent = ($Info.Summary -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
    Write-Host ""
    Write-Host $indentedContent.TrimEnd()
    Write-Host ""

    # Common pitfalls
    if ($Info.CommonPitfalls) {
        $pitfallsRuleParams = @{
            Title = " Common Pitfalls to Avoid "
            Color = "Yellow"
        }
        Write-SpectreRule @pitfallsRuleParams | Out-Host

        # Write pitfalls content directly (preserves ANSI codes)
        $indentedContent = ($Info.CommonPitfalls -split "`r?`n" | ForEach-Object { "  $_" }) -join "`n"
        Write-Host ""
        Write-Host $indentedContent.TrimEnd()
        Write-Host ""
    }

    $ruleParams = @{
        Color = $ColorTheme.SeparatorColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # Navigation - no Enter key
    Write-Host "`n[N]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Next  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    Write-Host "[P]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Previous  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground
    Write-Host "[Q]" -NoNewline -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host " Quit  " -NoNewline -ForegroundColor $ColorTheme.NavTextForeground

    # Progress indicator
    Write-Host "[" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
    Write-Host "$PageNumber" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
    Write-Host "/" -NoNewline -ForegroundColor $ColorTheme.ProgressTextForeground
    Write-Host "$TotalPages" -NoNewline -ForegroundColor $ColorTheme.ProgressForeground
    Write-Host "]" -ForegroundColor $ColorTheme.ProgressTextForeground -NoNewline
}

function Invoke-DemoCode {
    param(
        [Parameter(Mandatory)]
        [object[]]$Demos,

        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [Runspace]$Runspace
    )

    $demo = $Demos[$Index]

    $powershell = [PowerShell]::Create()
    $powershell.Runspace = $Runspace

    try {
        # Run setup (hidden) in the runspace
        $rawOutput = @(
            $location = $demo.CodeBlock.Ast.Extent.File
            if ($location) {
                $parentDir = Split-Path -Path $location -Parent

                $powershell.Commands.Clear()
                $powershell.Streams.ClearStreams()
                $null = $powershell.AddScript('Set-Location -LiteralPath $args[0]').AddArgument($parentDir)
                $null = $powershell.Invoke()
            }

            if ($demo.SetupBlock) {
                $out = Invoke-InDemoRunspace -PowerShell $powershell -ScriptBlock $demo.SetupBlock -ErrorOnly
                if ($out) {
                    "$($PSStyle.Foreground.BrightYellow)(Setup Error Output)$($PSStyle.Reset)`n$out"
                }
            }

            # Execute the demo code block
            Invoke-InDemoRunspace -PowerShell $powershell -ScriptBlock $demo.CodeBlock

            # Run teardown (hidden) in the runspace
            if ($demo.TeardownBlock) {
                $out = Invoke-InDemoRunspace -PowerShell $powershell -ScriptBlock $demo.TeardownBlock -ErrorOnly
                if ($out) {
                    "$($PSStyle.Foreground.BrightYellow)(Teardown Error Output)$($PSStyle.Reset)`n$out"
                }
            }
        )

        $codeOutput = $rawOutput -join "`n"
        if ([string]::IsNullOrWhiteSpace($codeOutput)) {
            return "$($PSStyle.Foreground.BrightBlack)(No output)$($PSStyle.Reset)"
        }

        $codeOutput
    }
    catch {
        "$($PSStyle.Foreground.BrightRed)Error: $_$($PSStyle.Reset)"
    }
    finally {
        $powershell.Dispose()
    }
}

function Show-LandingPage {
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,

        [Parameter(Mandatory)]
        [hashtable]$ColorTheme
    )

    Clear-Host

    # Create two-column layout with name on left and image on right
    # Left column - Name in blocky ASCII art (more compact)
    $leftContent = @"
[$($ColorTheme.TitleColor)]     ██╗ ██████╗ ██████╗ ██████╗  █████╗ ███╗   ██╗[/]
[$($ColorTheme.TitleColor)]     ██║██╔═══██╗██╔══██╗██╔══██╗██╔══██╗████╗  ██║[/]
[$($ColorTheme.TitleColor)]     ██║██║   ██║██████╔╝██║  ██║███████║██╔██╗ ██║[/]
[$($ColorTheme.TitleColor)]██   ██║██║   ██║██╔══██╗██║  ██║██╔══██║██║╚██╗██║[/]
[$($ColorTheme.TitleColor)]╚█████╔╝╚██████╔╝██║  ██║██████╔╝██║  ██║██║ ╚████║[/]
[$($ColorTheme.TitleColor)] ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝[/]
[$($ColorTheme.TitleColor)]██████╗  ██████╗ ██████╗ ███████╗ █████╗ ███╗   ██╗[/]
[$($ColorTheme.TitleColor)]██╔══██╗██╔═══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║[/]
[$($ColorTheme.TitleColor)]██████╔╝██║   ██║██████╔╝█████╗  ███████║██╔██╗ ██║[/]
[$($ColorTheme.TitleColor)]██╔══██╗██║   ██║██╔══██╗██╔══╝  ██╔══██║██║╚██╗██║[/]
[$($ColorTheme.TitleColor)]██████╔╝╚██████╔╝██║  ██║███████╗██║  ██║██║ ╚████║[/]
[$($ColorTheme.TitleColor)]╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝[/]

[dim]
                 ╔═══════════╗
                 ║  he/him   ║
                 ╚═══════════╝
[/]
"@

    # Right column - Image
    $imageContent = Get-SpectreImage -ImagePath $ImagePath -MaxWidth 30

    # Display columns side by side
    @($leftContent, $imageContent) | Format-SpectreColumns -Expand | Out-Host

    $ruleParams = @{
        Title = " Welcome to PSConfEU 2026 "
        Color = $ColorTheme.RuleColor
    }
    Write-SpectreRule @ruleParams | Out-Host

    # About me panel
    $aboutText = @(
        "Principal Software Engineer at Red Hat, where I focus on making Ansible play nice with Windows. "
        "I spend my days wrestling with PowerShell, Python, and C# to build bridges between the penguin "
        "and the window. When I'm not debugging cross-platform quirks, I'm probably overthinking another "
        "edge case. Pretty boring person overall, but my code occasionally does interesting things."
        "`n`n"
        "GitHub: jborean93`n"
        "BlueSky: jborean.bsky.social"
    ) -join ""

    $panelParams = @{
        Data   = $aboutText
        Header = "About Me"
        Expand = $true
        Color  = $ColorTheme.PanelColor
    }
    Format-SpectrePanel @panelParams | Out-Host

    # Navigation
    Write-Host "  Press [Enter] to continue to demos" -ForegroundColor $ColorTheme.NavLabelForeground
    Write-Host "  Press [Q] to quit" -ForegroundColor $ColorTheme.NavLabelForeground -NoNewline

    while ($true) {
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            "Enter" {
                return $true
            }
            "Q" {
                Clear-Host
                Write-Host "Thanks for stopping by! 👋" -ForegroundColor $ColorTheme.ExitForeground
                return $false
            }
        }
    }
}

function Start-DemoPresentation {
    param(
        [Parameter(Mandatory)]
        [object[]]$Pages,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter()]
        [int]$StartIndex = 0,

        [Parameter(Mandatory)]
        [hashtable]$ColorTheme
    )

    # Local presentation state
    $currentIndex = $StartIndex
    $hasRun = $false
    $lastOutput = ""

    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.Open()

    try {
        while ($true) {
            $page = $Pages[$currentIndex]

            # Display appropriate page type
            switch ($page.Type) {
                "Pre" {
                    Show-PrePage -BannerContent $Title -Info $page.Info `
                        -PageNumber ($currentIndex + 1) -TotalPages $Pages.Count `
                        -ColorTheme $ColorTheme
                }
                "Demo" {
                    # Create array with just this demo for compatibility
                    $singleDemo = @($page.Demo)
                    Show-DemoFrame -Demos $singleDemo -Title $Title -Index 0 `
                        -HasExecuted $hasRun -Output $lastOutput `
                        -PageNumber ($currentIndex + 1) -TotalPages $Pages.Count `
                        -TopicTitle $page.Info.Title `
                        -ColorTheme $ColorTheme
                }
                "Post" {
                    Show-PostPage -BannerContent $Title -Info $page.Info `
                        -PageNumber ($currentIndex + 1) -TotalPages $Pages.Count `
                        -ColorTheme $ColorTheme
                }
            }

            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                "Enter" {
                    # Only works on demo pages
                    if ($page.Type -eq "Demo") {
                        # Execute demo code
                        $singleDemo = @($page.Demo)
                        $lastOutput = Invoke-DemoCode -Demos $singleDemo -Index 0 -Runspace $runspace
                        $hasRun = $true
                    }
                    # No-op for pre/post pages
                }
                { $_ -in "N", "RightArrow" } {
                    if ($currentIndex -lt ($Pages.Count - 1)) {
                        $currentIndex++
                        $hasRun = $false
                        $lastOutput = ""
                    }
                }
                { $_ -in "P", "LeftArrow" } {
                    if ($currentIndex -gt 0) {
                        $currentIndex--
                        $hasRun = $false
                        $lastOutput = ""
                    }
                }
                "C" {
                    # Clear output - only works on demo pages
                    if ($page.Type -eq "Demo") {
                        $hasRun = $false
                        $lastOutput = ""
                    }
                }
                "Q" {
                    Clear-Host
                    Write-Host "Thanks for watching! 👋" -ForegroundColor $ColorTheme.ExitForeground
                    return
                }
            }

            if ($page.Type -eq "Demo") {
                $runspace.ResetRunspaceState()
            }
        }
    }
    finally {
        $runspace.Dispose()
    }
}

try {
    # Hide cursor for entire presentation
    [Console]::CursorVisible = $false

    # Create color theme based on mode
    $colorTheme = if ($LightMode) {
        @{
            # Spectre colors (markup strings)
            TitleColor = "DarkCyan"
            RuleColor = "Blue"
            PanelColor = "DarkBlue"
            CodeRuleColor = "DarkGreen"
            OutputRuleColor = "DarkMagenta"
            SeparatorColor = "Grey50"

            # TextMate themes
            PowerShellTheme = 'LightPlus'

            # Console colors
            TitleForeground = [ConsoleColor]::DarkCyan
            PromptForeground = [ConsoleColor]::DarkYellow
            NavLabelForeground = [ConsoleColor]::Black
            NavTextForeground = [ConsoleColor]::DarkGray
            ProgressForeground = [ConsoleColor]::DarkCyan
            ProgressTextForeground = [ConsoleColor]::DarkGray
            LineNumberForeground = "$($PSStyle.Foreground.FromRgb(100, 100, 100))"
            ExitForeground = [ConsoleColor]::DarkCyan
        }
    } else {
        @{
            # Spectre colors (markup strings)
            TitleColor = "Cyan1"
            RuleColor = "Cyan1"
            PanelColor = "Blue"
            CodeRuleColor = "Green"
            OutputRuleColor = "Magenta"
            SeparatorColor = "Grey"

            # TextMate themes
            PowerShellTheme = 'DarkPlus'

            # Console colors
            TitleForeground = [ConsoleColor]::Cyan
            PromptForeground = [ConsoleColor]::Yellow
            NavLabelForeground = [ConsoleColor]::White
            NavTextForeground = [ConsoleColor]::Gray
            ProgressForeground = [ConsoleColor]::Cyan
            ProgressTextForeground = [ConsoleColor]::DarkGray
            LineNumberForeground = $PSStyle.Foreground.BrightBlack
            ExitForeground = [ConsoleColor]::Cyan
        }
    }

    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DemoPath)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "Demo path not found: $DemoPath"
    }
    if (-not (Get-Item -LiteralPath $resolvedPath).PSIsContainer) {
        throw "Demo path is not a directory: $DemoPath"
    }

    # Check for banner.txt in the demo directory
    $bannerPath = Join-Path $resolvedPath "banner.txt"
    if (-not (Test-Path -LiteralPath $bannerPath)) {
        throw "No banner.txt found in $resolvedPath"
    }
    $bannerContent = Get-Content -LiteralPath $bannerPath -Raw

    # Show landing page if StartAt is 0 (default)
    if ($StartAt -eq 0) {
        $imagePath = Join-Path $PSScriptRoot "ME.png"
        if (Test-Path $imagePath) {
            $shouldContinue = Show-LandingPage -ImagePath $imagePath -ColorTheme $colorTheme
            if (-not $shouldContinue) {
                # User chose to quit from landing page
                return
            }
        }
        # Continue to first demo
        $StartAt = 1
    }

    # Load demo files and separate Info from Demo objects
    $demoFiles = Get-ChildItem -Path $resolvedPath -Filter "*.demos.ps1" | Sort-Object Name

    $PSDefaultParameterValues['Format-PowerShell:Theme'] = $colorTheme.PowerShellTheme

    $demoSets = foreach ($file in $demoFiles) {
        Write-Verbose "Loading demo file: $($file.FullName)"

        $info = $null
        $demos = @()

        # Load file and capture Info and Demo objects
        $results = @(. $file.FullName)
        foreach ($result in $results) {
            # Check if it's an Info object (has Introduction property)
            if ($null -ne $result -and
                $result.PSObject.Properties.Name -contains 'Introduction') {
                $info = $result
            }
            # Otherwise it's a Demo object (has CodeBlock property)
            elseif ($null -ne $result -and
                    $result.PSObject.Properties.Name -contains 'CodeBlock') {
                $demos += $result
            }
        }

        # If no Info block was found, create a default one
        if ($null -eq $info) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $info = [PSCustomObject]@{
                Title = $fileName
                Introduction = "Demos from $fileName"
                KeyConcepts = @()
                Summary = "End of $fileName demos."
                CommonPitfalls = ""
            }
        }

        [PSCustomObject]@{
            File = $file
            Info = $info
            Demos = $demos
        }
    }

    $PSDefaultParameterValues.Remove('Format-PowerShell:Theme')

    if ($demoSets.Count -eq 0) {
        throw "No demo files found in $DemoPath"
    }

    # Flatten into page array: pre, demos, post for each file
    $pages = @()
    foreach ($demoSet in $demoSets) {
        # Pre-page
        $pages += [PSCustomObject]@{
            Type = "Pre"
            Info = $demoSet.Info
        }

        # Demo pages - include Info so we know the topic title
        foreach ($demo in $demoSet.Demos) {
            $pages += [PSCustomObject]@{
                Type = "Demo"
                Demo = $demo
                Info = $demoSet.Info
            }
        }

        # Post-page
        $pages += [PSCustomObject]@{
            Type = "Post"
            Info = $demoSet.Info
        }
    }

    if ($pages.Count -eq 0) {
        throw "No pages to display"
    }

    # Validate start index
    if ($StartAt -lt 1 -or $StartAt -gt $pages.Count) {
        throw "StartAt must be between 1 and $($pages.Count)"
    }

    $presentationParams = @{
        Pages      = $pages
        Title      = $bannerContent
        StartIndex = $StartAt - 1
        ColorTheme = $colorTheme
    }
    Start-DemoPresentation @presentationParams
}
finally {
    # Always restore cursor visibility
    [Console]::CursorVisible = $true
}
