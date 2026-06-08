# $PSEdition is a built-in variable.
$PSEdition

# Get-Module has a -PSEdition parameter.
Get-Module -ListAvailable -PSEdition Desktop

# Proxy it.
$metadata = [System.Management.Automation.CommandMetadata]::new((Get-Command Get-Module))
$paramBlock = [System.Management.Automation.ProxyCommand]::GetParamBlock($metadata)
$cmdletBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($metadata)

Invoke-Expression "function ProxyGetModule { 
        $cmdletBinding param($paramBlock) `"MOCKED!`" 
    }"

# Show the definition
$paramBlock -split "`n" | Select-String 'PSEdition' -Context 3,0

# Cannot overwrite variable PSEdition because it is read-only or constant.
ProxyGetModule -ListAvailable -PSEdition Desktop

# other built-in variables that conflict:
# $Host, $PID, $Error, $ExecutionContext, $PSVersionTable,
# $true, $false, $HOME, $PSHOME, $PSCulture, $PSUICulture,
# $ShellId, $IsWindows, $IsMacOS, $IsCoreCLR, $?,
# $ConsoleFileName, $EnabledExperimentalFeatures
