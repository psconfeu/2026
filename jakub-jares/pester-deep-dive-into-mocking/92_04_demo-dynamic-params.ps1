# Dynamic parameters are resolved at runtime, not from metadata.
# Get-ChildItem -Path Cert:\ gets -CodeSigningCert from the Cert provider.
Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

# ProxyCommand doesn't know about it
$metadata = [System.Management.Automation.CommandMetadata]::new(
    (Get-Command Get-ChildItem))
$metadata.Parameters.ContainsKey("CodeSigningCert") # False

# So we do what Pester does: instantiate the cmdlet, inject engine
# context via reflection, and call GetDynamicParameters() on it.
# Mock.ps1:1505-1608

$CmdletName = "Get-ChildItem"
$Parameters = @{ Path = "Cert:\CurrentUser\My" }

$command = Get-Command -Name $CmdletName -CommandType Cmdlet

# does it even have dynamic params?
$command.ImplementingType.GetInterface('IDynamicParameters', $true)

# instantiate the cmdlet class directly
$cmdlet = $command.ImplementingType::new()

# inject engine context via reflection (it's not public)
$flags = [System.Reflection.BindingFlags]'Instance, Nonpublic'
$context = $ExecutionContext.GetType().GetField('_context', $flags)
    .GetValue($ExecutionContext)
[System.Management.Automation.Cmdlet].GetProperty('Context', $flags)
    .SetValue($cmdlet, $context, $null)

# set bound parameters via reflection so the cmdlet can resolve dynamic params
foreach ($keyValuePair in $Parameters.GetEnumerator()) {
    $property = $cmdlet.GetType().GetProperty($keyValuePair.Key)
    if ($null -eq $property -or -not $property.CanWrite) { continue }

    $isParameter = [bool]($property.GetCustomAttributes(
        [System.Management.Automation.ParameterAttribute], $true))
    if (-not $isParameter) { continue }

    $property.SetValue($cmdlet, $keyValuePair.Value, $null)
}

# finally get the dynamic parameters
# Love the comma. Don't delete it.
, $cmdlet.GetDynamicParameters()
