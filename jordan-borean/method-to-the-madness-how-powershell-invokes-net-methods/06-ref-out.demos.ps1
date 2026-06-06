Info {
    Title "Ref and Out Parameters"

    Introduction "Use [ref] to pass parameters by reference for methods with ref or out parameters."

    KeyConcepts @(
        "Using [ref] for ref and out parameters"
        "Reflection with MakeByRefType() and args as an array"
    )

    $refExample = @'
$val = 1
[RefMethod]::Adjust([ref]$val, 2)
$val  # Now 3
'@ | Format-PowerShell

    Summary @"
PowerShell treats ref and out parameters the same - use [ref]:

$refExample

With reflection, use MakeByRefType() to make a ref type and check the array after Invoke().
"@

    CommonPitfalls @"
• Forgetting [ref] wrapper
• Not retrieving the value from the array after reflection Invoke()
"@
}

Demo "Ref parameters" {
    Description "Shows how PowerShell uses the [ref] modifier to provide a value by reference"

    Code {
        Add-Type -TypeDefinition @'
        public class RefMethodTest
        {
            public static void AdjustInt(ref int val, int toAdd)
            {
                val += toAdd;
            }
        }
'@

        $val = 1
        [RefMethodTest]::AdjustInt([ref]$val, 2)
        $val
    }
}

Demo "Out parameters" {
    Description "Shows how PowerShell treats out arguments the same as [ref]"

    Code {
        $val = 0
        [int]::TryParse('1', [ref]$val)
        $val
    }
}

Demo "Ref and out args called through reflection" {
    Description "Shows how to call and use ref/out arguments with reflection"

    Code {
        $val = 0
        $meth = [int].GetMethod(
            'TryParse',
            [type[]]@([string], [int].MakeByRefType()))
        $methArgs = @('1', $val)

        $meth.Invoke($null, $methArgs)
        "`$val -eq $val"
        "`$methArgs[1] -eq $($methArgs[1])"
    }
}
