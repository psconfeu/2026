# We need this setting:
# "powershell.scriptAnalysis.settingsPath": "C:\\Temp\\VSCode\\CustomRules.psd1"

#CustomRules.psd1
<#

@{
    CustomRulePath      = 'C:\Temp\VSCode\Rules\*'
    RecurseCustomRulePath = $true
    IncludeDefaultRules = $true
    # Only use IncludeRules if you want a *subset* of rules, otherwise remove it
    IncludeRules        = @(
        'PSAvoidDefaultValueSwitchParameter',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSAvoidUsingCmdletAliases',
        'PSUseDeclaredVarsMoreThanAssignments',
        'Measure-*',   # <-- Only keep if you know you have a custom rule with this name
	    'PSPossibleIncorrectComparisonWithNull'
    )
}

#>