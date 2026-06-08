<#
.SYNOPSIS
    This is a sample function.

.DESCRIPTION
    This function is a sample to demonstrate comment-based help in PowerShell.

.PARAMETER Name
    The name of the person to greet.

.EXAMPLE
    SampleFunction -Name "John"
    This will output "Hello, John!"
.EXAMPLE
    SampleFunction -Name "Jane"
    This will output "Hello, Jane!"
.EXAMPLE
    SampleFunctionx -Name "Jane"
    This will output "Hello, Jane!"

.NOTES
    Author: Your Name
    Date: Today's Date
#>
function SampleFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-Output "Hello, $Name!"
}