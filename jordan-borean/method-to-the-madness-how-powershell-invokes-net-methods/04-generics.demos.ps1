Info {
    Title "Working with .NET Generics"

    Introduction "Generic types require some extra work to be used in PowerShell. With these demos we will cover how to work in the world of generics."

    KeyConcepts @(
        "How to construct a generic type instance"
        "How to invoke a method with generic types"
        "Method type inference vs explicit generic args"
        "Using reflection with MakeGenericType/Method"
    )

    $instanceExample = @'
[System.Collections.Generic.List[int]]::new()
'@ | Format-PowerShell

    $methodExample = @'
$list.Add('1')  # Infers int from the instance type
'@ | Format-PowerShell

    $explicitExample = @'
[Linq.Enumerable]::OrderBy[int, int]([int[]]$array, { $_ })
'@ | Format-PowerShell

    Summary @"
Type parameters must be explicit for instances, but PowerShell often infers them for methods.

Creating instances - always explicit:

$instanceExample

Calling methods - often inferred:

$methodExample

When inference fails, be explicit:

$explicitExample

For PowerShell 5.1, use reflection with MakeGenericType() and MakeGenericMethod().
"@

    CommonPitfalls @"
• Referencing the actual generic type in pwsh requires backticks and the arity number 'List`1' not 'List<T>'
• Sometimes PowerShell cannot infer the type, either requires a hard cast or method type args
• Loosing your sanity dealing with reflection and more complex overloads, no help here sorry
"@
}

Demo "Generic type without type info" {
    Description "Shows how PowerShell fails to create a generic type if no generics are specified"

    Code {
        # public class List<T> {}
        [System.Collections.Generic.List]::new()
    }
}

Demo "Generic type with generic marker" {
    Description "Shows how PowerShell still fails even if the generic type marker (e.g., `1) is present"

    Code {
        [System.Collections.Generic.List`1]::new

        [System.Collections.Generic.List`1]::new()
    }
}

Demo "Creating generic type instance" {
    Description "Shows how to specify the types to create an instance of a generic type"

    Code {
        [System.Collections.Generic.List[int]]::new().GetType().FullName
    }
}

Demo "Generic type constructor through reflection" {
    Description "Shows how to call the constructor of a generic type through reflection"

    Code {
        $type = [System.Collections.Generic.List`1].MakeGenericType([int])
        $ctor = $type.GetConstructor(@())

        $list = $ctor.Invoke(@())
        $list.GetType().FullName
    }
}

Demo "Generic type with multiple type parameters" {
    Description "Shows how to specify multiple types when the generic type requires multiple generics"

    Code {
        # public class Dictionary<TKey, TValue> {}
        [System.Collections.Generic.Dictionary[string, int]]::new().GetType().FullName
    }
}

Demo "Generic methods on generic types" {
    Description "Shows how calling a generic method on a generic type infers the T from the instance itself"

    Code {
        $list = [System.Collections.Generic.List[int]]::new()
        $list.Add('1')
        $list[0].GetType().Name

        $list.Add('fail')
    }
}

Demo "Generic method type inference" {
    Description "Shows how PowerShell can infer the type when possible when invoking a generic method"

    Code {
        [Linq.Enumerable]::OrderBy

        [Linq.Enumerable]::OrderBy(
            @(1, 4, 2, 3),
            [Func[object, int]]{
                param($Item)

                $Item
            })
    }
}

Demo "Generic method inference failure" {
    Description "Shows how PowerShell cannot always infer the generic type to use"

    Code {
        [Linq.Enumerable]::OrderBy(
            @(1, 4, 2, 3),
            {
                param($Item)

                $Item
            })
    }
}

Demo "Explicit generic type specification" {
    Description "Shows how to provide explicit generic types when PowerShell's generic inference is not possible"

    Code {
        [Linq.Enumerable]::OrderBy[object, int](
            @(1, 4, 2, 3),
            {
                param($Item)

                $Item
            })
    }
}

Demo "Generic method with explicit return type" {
    Description "Shows how to be explicit with return types when a return T cannot be provided otherwise"

    Code {
        $array = [Array]::Empty[int]()
        $array.GetType().FullName
    }
}

Demo "Generic method through reflection (5.1)" {
    Description "Shows how to use reflection to invoke a generic method that cannot be inferred (required for PowerShell 5.1 support)"

    Code {
        $meth = [Array].GetMethod('Empty').MakeGenericMethod([int])
        $array = $meth.Invoke($null, @())
        $array.GetType().FullName
    }
}
