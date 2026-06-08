# -Name and -Id are different parameter sets, can't use both
Get-Process -Name "pwsh" -Id 1234

# Our mock needs the same behavior
$metadata = [System.Management.Automation.CommandMetadata]::new((Get-Command Get-Process))
$cmdletBinding = [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute(
    $metadata)
$paramBlock = [System.Management.Automation.ProxyCommand]::GetParamBlock($metadata)

Invoke-Expression "function StubbornProcess {
    $cmdletBinding 
    param($paramBlock) 
    'YOUR PROCESSES ARE MINE!'
}"

StubbornProcess -Name "pwsh"
StubbornProcess -Id 1234

# same issue as before
StubbornProcess -Name "pwsh" -Id 1234
