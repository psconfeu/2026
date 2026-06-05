Info {
    Title "Non-Public Members"

    Introduction "Access internal and private types, methods, and members using reflection."

    KeyConcepts @(
        "Finding non-public types with `$assemblyObj.GetType('TypeNameHere')"
        "Using BindingFlags for non-public members"
    )

    Summary @"
Reflection can access non-public types and members when needed for advanced scenarios.

Use `$assembly.GetType('TypeNameHere') for non-public types and BindingFlags like 'Instance, NonPublic' for methods.
"@

    CommonPitfalls @"
• Expecting non-public types to resolve with -as [type]
• Using the wrong assembly to find a type
• Not specifying correct BindingFlags
• Relying on APIs that can change across releases
"@
}

Demo "Finding non-public types" {
    Description "Shows how to use reflection to find a type that is not public"

    Code {
        "Normal Type Resolution: '$('System.Management.Automation.TypeAccelerators' -as [type])'"

        $asmWithType = [PSObject].Assembly
        $type = $asmWithType.GetType('System.Management.Automation.TypeAccelerators')
        "Reflection: '$type'"
    }
}

Demo "Public members of private types" {
    Description "Public members of non-public types are not special once we have our type object"

    Code {
        $asmWithType = [PSObject].Assembly
        $ta = $asmWithType.GetType('System.Management.Automation.TypeAccelerators')

        # TypeAccelerators is non-public but the Add method on it is public
        # we can access it like normal once we have our type.
        $ta::Add
    }
}

Demo "Non-public instance methods" {
    Description "Shows how to use reflection to invoke an instance method that is not public"

    Code {
        Add-Type -TypeDefinition @'
        public class InstanceReflectionPrivateTest
        {
            private int _field = 0;

            public InstanceReflectionPrivateTest(int val)
            {
                _field = val;
            }

            internal int NonPublicMethod() => _field;
        }
'@

        $obj = [InstanceReflectionPrivateTest]::new(10)
        $meth = $obj.GetType().GetMethod(
            'NonPublicMethod',
            [Reflection.BindingFlags]'Instance, NonPublic',
            @())

        $meth.Invoke($obj, @())
    }
}

Demo "Non-public static methods" {
    Description "Shows how to use reflection to invoke a static method that is not public"

    Code {
        Add-Type -TypeDefinition @'
        public class StaticReflectionPrivateTest
        {
            internal static int NonPublicMethod() => -1;
        }
'@

        $meth = [StaticReflectionPrivateTest].GetMethod(
            'NonPublicMethod',
            [Reflection.BindingFlags]'Static, NonPublic',
            @())

        $meth.Invoke($null, @())
    }
}
