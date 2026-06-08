cd .\2\Skeleton_Advanced
Invoke-ScriptAnalyzer -Path .\TestScript.ps1 -CustomRulePath .\Rules\* 

# Lets fix it

Invoke-ScriptAnalyzer -Path .\TestScript.ps1 -CustomRulePath .\Rules\* -Fix
cd .\..\..


