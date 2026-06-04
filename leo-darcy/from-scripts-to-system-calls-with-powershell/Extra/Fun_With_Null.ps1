#Quick script to prove that $null does not equal a C null/Pointer Null see https://www.thoughtco.com/definition-of-null-958118 for a bit more explination

Write-Output "`$null -eq [System.IntPtr]::Zero - $($null -eq [System.IntPtr]::Zero)"
Write-Output "0 -eq [System.IntPtr]::Zero - $(0 -eq [System.IntPtr]::Zero)"
Write-Output "[System.IntPtr]::Zero Type - $([System.IntPtr]::Zero.GetType())"
Write-Output "Null - $null"
Write-Output "[System.IntPtr]::Zero -$([System.IntPtr]::Zero)" 
Write-Output "[System.IntPtr]::new(-1) - $([System.IntPtr]::new(-1))"