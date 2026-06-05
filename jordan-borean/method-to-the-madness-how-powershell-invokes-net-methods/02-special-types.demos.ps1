Info {
    Title "Special Parameter Types"

    Introduction "How to handle params arrays, null values, nullable types, and extension methods in PowerShell."

    KeyConcepts @(
        "Params arrays - individual args vs array"
        "Null handling"
        "How null works with string and [NullString]::Value"
        "Extension methods as static methods"
    )

    $nullExample = @'
[NullAsStringTest]::IsNull([NullString]::Value)
'@ | Format-PowerShell

    Summary @"
PowerShell handles special .NET types with specific rules:

Params: Pass individually or as array - PowerShell chooses the overload

Null: Beware when passing null to a string typed arg, you may want [NullString]::Value intead:

$nullExample

Extension methods: Call as static methods, not instance methods
"@

    CommonPitfalls @"
• Passing `$null expecting it to be null for strings
• Trying to call extension methods as instance methods
"@
}

Demo "Params as args" {
    Description "Shows how PowerShell handles params arguments passed individually"

    Code {
        Trace-Command -Name MethodInvocation -Expression {
            [string]::Join('-', 'a', 'b', 'c')
        } -PSHost
    }
}

Demo "Params as array" {
    Description "Shows how params can be passed as an array"

    Code {
        Trace-Command -Name MethodInvocation -Expression {
            [string]::Join('-', @('a', 'b', 'c'))
        } -PSHost
    }
}

Demo "Params as hardcoded array type" {
    Description "Shows how a hard cast can help guide which overload to use"

    Code {
        Trace-Command -Name MethodInvocation -Expression {
            [string]::Join('-', [string[]]@('a', 'b', 'c'))
        } -PSHost
    }
}

# Demo "Null as value" {
#     Description "Shows how to pass null as an argument to any typed parameter"

#     Code {
#         Add-Type -TypeDefinition @'
#         public class NullAsObjectTest
#         {
#             public static bool IsNull(object obj) => obj is null;
#         }
# '@
#         [NullAsObjectTest]::IsNull($null)
#     }
# }

Demo "Null as string typed arg" {
    Description "Shows how to pass null as an argument to a string typed parameter"

    Code {
        Add-Type -TypeDefinition @'
        public class NullAsStringTest
        {
            public static bool IsNull(string obj) => obj is null;
        }
'@
        [NullAsStringTest]::IsNull($null)
    }
}

Demo "[NullString]::Value for null" {
    Description "Shows how to use [NullString]::Value to truly pass in null for a string argument"

    Code {
        Add-Type -TypeDefinition @'
        public class NullAsStringTest
        {
            public static bool IsNull(string obj) => obj is null;
        }
'@
        [NullAsStringTest]::IsNull([NullString]::Value)
    }
}

# Demo "Null for value types" {
#     Description "Shows how null for a ValueType becomes the default value, e.g. int becomes 0"

#     Code {
#         Add-Type -TypeDefinition @'
#         public class NullAsIntTest
#         {
#             public static int GetInt(int i) => i;
#         }
# '@
#         [NullAsIntTest]::GetInt($null)
#     }
# }

# Demo "Nullable value types" {
#     Description "Shows how value typed arguments can be null when they are nullable types"

#     Code {
#         Add-Type -TypeDefinition @'
#         public class NullableValueTypeTest
#         {
#             public static bool IsNull(int? val) => val is null;
#         }
# '@
#         [NullableValueTypeTest]::IsNull($null)
#         [NullableValueTypeTest]::IsNull(0)
#     }
# }

Demo "Extension methods invocation" {
    Description "Extension methods are not special in PowerShell, they are treated as static methods"

    Code {
        Add-Type -TypeDefinition @'
        public static class ExtensionMethodTest
        {
            public static string AppendSpecialMarker(this string instance, string value)
                => $"{instance} - {value}";
        }
'@

        [ExtensionMethodTest]::AppendSpecialMarker("value", "works")

        "value".AppendSpecialMarker("fails")
    }
}
