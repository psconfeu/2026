Info {
    Title ".NET Method Invocation Basics"

    Introduction "Learn the fundamentals of calling .NET instance and static methods, constructors, as well as using reflection."

    KeyConcepts @(
        "Instance vs static method invocation"
        "Constructor syntax with ::new()"
        "Reflection with GetMethod() and Invoke()"
        "Overload tracing"
    )

    $directExample = @'
# Instance: $obj.Method(args)
"test".StartsWith("te")

# Static: [Type]::Method(args)
[Math]::Sqrt(4)

# Constructor: [Type]::new(args)
[Text.StringBuilder]::new()
'@ | Format-PowerShell

    Summary @"
PowerShell invokes .NET method with a simple Method(...) syntax:

$directExample

What differs is whether the method is an instance, static, constructor method.

Reflection is also available as an escape hatch if PowerShell does not expose what you need but take care it can be quite verbose.
"@

    CommonPitfalls @"
• Forgetting parentheses - accessing the method object instead of calling it
• Wrong/unexpected overload chosen, Trace-Command and casting helps here
"@
}

Demo "Invoking .NET instance method" {
    Description "Shows how to invoke a .NET instance method"

    Code {
        "Testing -".StartsWith("Test")
    }
}

Demo "Invoke method using dynamic value for the name" {
    Description "PowerShell's member lookup happens at runtime and supports a string expression"

    Code {
        $methodName = "StartsWith"
        $shortName = "Starts"

        # Both of these examples work
        "Testing -".$methodName("Test")
        "Testing -"."${shortName}With"("Test")
    }
}

Demo "Use reflection to invoke an instance method" {
    Description "PowerShell can use reflection to also invoke instance methods"

    Code {
        $obj = "Testing -"
        $meth = $obj.GetType().GetMethod('StartsWith', [type[]]@([string]))
        $meth.Invoke(
            $obj,  # Instance to invoke this on
            @("Test"))  # Args as an array for the method
    }
}

Demo "Invoking .NET static method" {
    Description "Shows how to invoke a .NET static method"

    Code {
        [Math]::Sqrt(4)
    }
}

Demo "Invoking .NET static method with dynamic values" {
    Description "Shows how to invoke a .NET static method with dynamic values for the type and method name"

    Code {
        $type = [Math]
        $methodName = "Sqrt"

        $type::$methodName(4)
    }
}

Demo "Use reflection to invoke a static method" {
    Description "PowerShell can use reflection to also invoke static methods"

    Code {
        $meth = [Math].GetMethod('Sqrt', [type[]]@([int]))
        $meth.Invoke(
            $null,  # Static methods have no instance so this is null
            @(4))

    }
}

Demo "Invoking constructor" {
    Description "Shows how to invoke a type's constructor"

    Code {
        [Text.StringBuilder]::new()
    }
}

Demo "Invoking constructor through reflection" {
    Description "Shows how to invoke a type's constructor through reflection"

    Code {
        $ctor = [Text.StringBuilder].GetConstructor(@())
        $ctor.Invoke(@())
    }
}

Demo "Listing methods" {
    Description "Shows how to list instance methods"

    Code {
        "" | Get-Member -MemberType Method
    }
}

Demo "Listing static methods" {
    Description "Show how to list static methods"

    Code {
        [string] | Get-Member -MemberType Method -Static
    }
}

Demo "Showing overloads for instance methods" {
    Description "Get PowerShell to show method overloads for instance methods"

    Code {
        "".Split
    }
}

Demo "Showing overloads for static methods" {
    Description "Get PowerShell to show method overloads for static methods"

    Code {
        [String]::Format
    }
}

Demo "Logging to show overload chosen" {
    Description "Trace-Command can show the overload selected (7.6+)"

    Code {
        Trace-Command -Name MethodInvocation -Expression {
            "abc [|] def [|] ghi".Split(" [|]")

            "abc [|] def [|] ghi".Split(' ', '[', '|', ']')
        } -PSHost | Out-Null
    }
}

Demo "Splat like argument invocation" {
    Description "We can splat an array as method arguments using .Invoke()"

    Code {
        Add-Type -TypeDefinition @'
        public class SplatTest
        {
            public static string Method(string a, string b, string c)
                => $"{a}-{b}-{c}";
        }
'@

        [SplatTest]::Method('a', 'b', 'c')

        $mySplat = 'a', 'b', 'c'
        [SplatTest]::Method.Invoke($mySplat)
    }
}
