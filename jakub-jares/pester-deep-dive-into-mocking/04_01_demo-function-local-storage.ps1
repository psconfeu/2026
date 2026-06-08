# The mock runs in YOUR scope. Pester doesn't exist there.
# How does it call back?

# $MyInvocation.MyCommand is the function object itself.
function Smuggler {
    $self = $MyInvocation.MyCommand
    $self.Mock.CallCount++
    & $self.Mock.Callback
}

function Cargo { "I was called!" }

# bolt data onto the function
$fn = Get-Item function:Smuggler
$fn.psobject.Properties.Add(
    [PSNoteProperty]::new('Mock', @{
        Callback  = Get-Item function:Cargo
        CallCount = 0
    })
)

Smuggler
Smuggler

# write the call count
$fn.Mock.CallCount

# cleanup
Remove-Item Function:\Smuggler -Force
Remove-Item Function:\Cargo -Force
