Info {
    Title "Type Casting"

    Introduction "Understand PowerShell's automatic casting and when to use explicit casts."

    KeyConcepts @(
        "Automatic casting by PowerShell"
        "Explicit casts to control overload selection"
        "Reflection limitations with casting"
    )

    Summary @"
PowerShell automatically casts arguments when possible, but you can override with explicit casts to select specific overloads.

Reflection doesn't auto-cast - .NET is in charge and more strict.
"@

    CommonPitfalls @"
• Relying on PowerShell casting when using reflection
• Not understanding which overload PowerShell selected, casting can force pwsh's hand
"@
}

Demo "[int]::IsPositive overloads]" {
    Description "Show the overloads for [int]::IsPositive"

    Code {
        [int]::IsPositive
    }
}


Demo "PowerShell auto casting" {
    Description "PowerShell will automatically cast an object if it can"

    Code {
        [int]::IsPositive("1")
    }
}

Demo "Casting failure" {
    Description "PowerShell will error if the cast fails"

    Code {
        [int]::IsPositive("a")
    }
}

Demo "Explicit casting" {
    Description "We can explicitly cast an object to a type if we don't want to rely on PowerShell's logic"

    Code {
        Add-Type -TypeDefinition @'
        public class CastOverrideTest
        {
            public static string FromValue(int v)
                => "FromInt";

            public static string FromValue(string s)
                => "FromString";
        }
'@

        [CastOverrideTest]::FromValue('1')

        [CastOverrideTest]::FromValue([int]'1')
    }
}

Demo "Reflection limits casting support" {
    Description "When using reflection, .NET is in charge of casting which is more limited."

    Code {
        Add-Type -TypeDefinition @'
        public class CastOverrideReflectionTest
        {
            public static string FromValue(int v)
                => "FromInt";

            public static string FromValue(string s)
                => "FromString";
        }
'@

        # We select the int overload
        $meth = [CastOverrideReflectionTest].GetMethod(
            'FromValue',
            [type[]]@([int]))

        # Even though PowerShell would normally cast our string to an int
        # or select the proper overload, .NET won't do that here.
        $meth.Invoke($null, @('1'))
    }
}
