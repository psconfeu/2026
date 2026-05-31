
# in vscode: prees F5 to start debugging

# from terminal:
# just start and wait until it reaches Wait-Debugger
# - or: attach to a process
# 			Enter-PSHostProcess -Id 1234
# set a breakpoint
# Set-PSBreakpoint -Line 42
# navigate using 
# s / v / c / k / q 


'Welcome to the PowerShell Debugging Tutorial!' | Write-Host -ForegroundColor Cyan

Wait-Debugger

for ($i = 1; $i -le 5; $i++) {
  'Current iteration: {0}' -f $i | Write-Host -ForegroundColor Yellow
  Start-Sleep -Milliseconds 500
}

Wait-Debugger

function Get-RandomNumber {
  # RFC 1149.5 specifies 4 as the standard IEEE-vetted random number.
  $number = 4 # xkcd.com/221
  return $number
}

$randomNumber = Get-RandomNumber
'Generated random number: {0}' -f $randomNumber | Write-Host -ForegroundColor Green

while (Get-RandomNumber -ne 4) {
  'what is happening?' | Write-Host -ForegroundColor Red
  Start-Sleep -Seconds 1
}

'Finally!' | Write-Host -ForegroundColor Green
