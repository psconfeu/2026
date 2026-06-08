function Get-EndpointInfo {
    Param(
        [ValidateSet("Device","User")]
        $Type,
        $ID
    )
    Write-Host "Call Endpoint: /$Type/$ID/Info"
}

#endregion

#region also a simple solution, but users of the function dont have to type or complete the endpoint
function Get-EndpointInfo {
    Param(
        $ID,
        [Parameter(ParameterSetName = "User")]
        [switch] $User,
        [Parameter(ParameterSetName = "Device")]
        [switch] $Device
        )
        
        Write-Host "Call Endpoint: /$($PSCmdlet.ParameterSetName)/$ID/Info"
}
#endregion
<# 
    less text in process block, 
    if the routes may be not like the user e.g.:
        /User/alluser/<ID>/Info
        /Device/<Location>/<ID>/Info
        ...
    Bonus, no switching there   
#>
function Get-EndpointInfo {
    param (
        $ID,
        [Parameter(ParameterSetName='/User/{0}/Info')]
        [switch]$User,
        [Parameter(ParameterSetName='/Device/{0}/Info')]
        [switch]$Device
    )
    Write-Host "Call Endpoint: $($PSCmdlet.ParameterSetName -f $ID)"
}

