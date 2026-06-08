# Pester's fix: rename $PSEdition → $_PSEdition, add alias for binding
# Mock.ps1:1706 Repair-ConflictingParameters
# Mock.ps1:1805 $script:ConflictingParameterNames

$metadata = [System.Management.Automation.CommandMetadata]::new(
    (Get-Command Get-Module))

# rename conflicting param
$param = $metadata.Parameters["PSEdition"]
$param.Name = "_PSEdition"
### Fix: add original name as alias
$param.Aliases.Add("PSEdition")
$metadata.Parameters.Remove("PSEdition")
$null = $metadata.Parameters.Add("_PSEdition", $param)

$paramBlock = [System.Management.Automation.ProxyCommand]::GetParamBlock(
    $metadata)
$cmdletBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute(
    $metadata)

Invoke-Expression "function FixedGetModule { 
        $cmdletBinding 
        param($paramBlock) 
        `"MOCKED! 
        Real PSEdition:       `$PSEdition, 
        Parameter _PSEdition: `$_PSEdition`"
    }"

FixedGetModule -ListAvailable -PSEdition Desktop
