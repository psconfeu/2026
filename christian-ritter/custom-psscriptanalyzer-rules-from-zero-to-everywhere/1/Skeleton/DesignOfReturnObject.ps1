# -----------------------------------------------------------------------------
# A ScriptAnalyzer rule must return a DiagnosticRecord object.
# This object describes:
#   - WHAT the issue is (Message)
#   - WHERE it occurs (Extent)
#   - WHICH rule reported it (RuleName)
#   - HOW severe it is (Severity)
# -----------------------------------------------------------------------------

[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
    # Human-readable description of the issue
    Message = "This is a custom message describing the 'issue' found by the rule."

    # The AST extent that pinpoints the exact location in the script
    # In real rules, this should come from the AST node you are analyzing (e.g. $_.Extent)
    Extent  = $_.Extent

    # Name of your custom rule
    RuleName = 'MyCustomRule'

    # Severity level: Information, Warning, or Error
    Severity = "Warning"

    # Optional ID used for suppression scenarios
    RuleSuppressionID = "1337" # Very creative, for sure.
}

# suggested correction could look like this
$Test -eq $null


# -----------------------------------------------------------------------------
# IMPORTANT:
# The Extent is the most critical part for positioning.
# It tells ScriptAnalyzer:
#   - start/end line
#   - start/end column
#   - the exact text fragment
#
# Without a valid Extent, the issue cannot be mapped back to source code.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# For demonstration purposes, we can obtain a "real" extent by parsing a file.
# Normally, the AST is already provided to your rule by ScriptAnalyzer.
# -----------------------------------------------------------------------------

$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    ".\1\skeleton\TestScript.ps1",  # Any existing script file
    [ref]$null,
    [ref]$null
)

# -----------------------------------------------------------------------------
# Even if the extent is not related to the actual issue,
# ANY valid extent object is sufficient to construct a DiagnosticRecord.
# This is useful for demos or testing.
# -----------------------------------------------------------------------------

[Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
    Message = "Demo message using a reused AST extent."
    Extent  = $ast.EndBlock.Extent   # Real extent from parsed AST
    RuleName = 'MyCustomRule'
    Severity = "Warning"
    RuleSuppressionID = "1337"
}

# -----------------------------------------------------------------------------
# NOTE:
# While the Extent contains file information internally,
# ScriptAnalyzer does NOT always use it for display.
# The ScriptName is handled separately.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Preferred approach: use the constructor and explicitly pass ScriptName
# This ensures the diagnostic is correctly associated with a file.
# -----------------------------------------------------------------------------

[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]::new(
    "This is a custom message describing the 'issue' found by the rule.", # Message
    $ast.EndBlock.Extent,   # Location (Extent)
    "MyCustomRule",         # Rule name
    "Warning",              # Severity
    "C:\temp\demo.ps1"      # ScriptName (explicit file association)
)

# -----------------------------------------------------------------------------
# KEY TAKEAWAY:
#   Extent     = "Where in the code?"
#   ScriptName = "Which file does it belong to?"
#
# These are related, but intentionally separate concepts.
# -----------------------------------------------------------------------------