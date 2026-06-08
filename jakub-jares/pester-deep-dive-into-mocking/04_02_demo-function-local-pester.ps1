# How Pester does it — Mock.ps1:278-296

function PesterMock_script_Get-Greeting_demo {
    # zero local variables — everything on $MyInvocation.MyCommand.Mock
    $MyInvocation.MyCommand.Mock.Args = 
        $MyInvocation.MyCommand.Mock.ExecutionContext.SessionState.PSVariable.GetValue(
            'local:args')
    $MyInvocation.MyCommand.Mock.PSCmdlet = 
        $MyInvocation.MyCommand.Mock.ExecutionContext.SessionState.PSVariable.GetValue(
            'local:PSCmdlet')

    & $MyInvocation.MyCommand.Mock.Invoke_Mock -ArgumentList `
        $MyInvocation.MyCommand.Mock.Args
}

# Mock.ps1:278-296 — bolt functionLocalData onto the function
$fn = Get-Item function:PesterMock_script_Get-Greeting_demo
$fn.psobject.Properties.Add(
    [PSNoteProperty]::new('Mock', @{
        Args             = $null
        PSCmdlet         = $null
        SessionState     = $null
        ExecutionContext  = $ExecutionContext

        # stored references — callable from any scope
        Invoke_Mock      = { param($ArgumentList) "MOCKED with args: $ArgumentList" }

        Hook             = @{ CommandName = 'Get-Greeting' }
    })
)

PesterMock_script_Get-Greeting_demo "World"



# sometimes we want to leak variables
# $_____MockCallState = @{} in begin block
# survives begin/process/end
# inherited by nested mocks, but each begin block shadows it with its own local
function Collect {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)]$Item)
    begin {
        $______CallState = @{ Items = [Collections.Generic.List[object]]@() }
    }
    process {
        $______CallState.Items.Add($Item)
        if ($Item -eq 'recurse') {
            # we call ourself
            'x','y' | Collect 
        }
    }
    end {
        "captured: $($______CallState.Items -join ',')"
    }
}

'a','recurse','b' | Collect
