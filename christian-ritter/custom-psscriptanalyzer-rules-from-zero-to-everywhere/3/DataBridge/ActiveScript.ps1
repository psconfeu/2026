Write-Host 'Set Databridge Value'
[DataBridge]::Bridge = 'InitialValue'

Write-Host "Current DataBridge Value: $([DataBridge]::Bridge)"
# 
Invoke-DataBridge 'Firstagain'


# Check what the current value is
Write-Host "Current DataBridge Value: $([DataBridge]::Bridge)"
