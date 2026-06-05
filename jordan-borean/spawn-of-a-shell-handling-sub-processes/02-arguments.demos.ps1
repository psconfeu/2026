Info {
    Title "Command Line Arguments"

    Introduction "PowerShell handles arguments differently than bash or cmd. We'll look at quoting, variable expansion, splatting, and how to debug argument parsing with Trace-Command."

    KeyConcepts @(
        "Quote handling and variable expansion"
        "Splatting vs variable arrays"
        "Debugging with Trace-Command"
    )

    $codeExample = @'
$args = 'foo', 'bar', 'baz'
print_argv @args
'@ | Format-PowerShell

    Summary @"
PowerShell does its own parsing before passing arguments to native commands.

Key points:
  • PowerShell handles quote removal automatically
  • @ unpacks arrays, `$ keeps them as one argument
  • Use Trace-Command to debug argument parsing

Best practice - use splatting for dynamic argument lists:

$codeExample

This unpacks each element as a separate argument.
"@

    CommonPitfalls @"
  • Using `$args when you meant @args (or vice versa)
  • Expecting bash/cmd quoting rules to apply
"@
}

Demo "Positional arguments" {
    Description "Shows how arguments are supplied positionally to native commands"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        print_argv foo "bar" "baz qux"
    }
}

Demo "Positional arguments with single quotes" {
    Description "Shows how arguments are supplied positionally with single quoted values"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        print_argv foo 'bar' 'baz qux'
    }
}

Demo "Argument parsing trace" {
    Description "Shows how to use Trace-Command to see how PowerShell parses arguments for native commands"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        Trace-Command -Name ParameterBinding -Expression {
            print_argv foo "bar" "baz qux"
        } -PSHost
    }
}

Demo "Argument variables" {
    Description "Shows how PowerShell variables can be used for command line arguments"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        $cmdArgs = 'foo', 'bar', 'baz qux'
        $moreArgs = 'quux', 'corge'

        print_argv $cmdArgs $moreArgs 'inline arg'
    }
}

Demo "Argument splatting" {
    Description "Shows how splatting can pass an array of arguments to native commands"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        $cmdArgs = 'foo', 'bar', 'baz qux'
        $moreArgs = 'quux', 'corge'

        print_argv @cmdArgs @moreArgs 'inline arg'
    }
}

Demo "Array vs splatting" {
    Description "Shows how splatting handles nested arrays differently than variable expansion"

    Setup { Set-Alias print_argv "./argv/$($IsWindows ? 'win_argv.exe' : 'linux_argv')" }

    Code {
        $cmdArgs = @(
            'foo'
            'bar'
            , @('baz', 'qux')
        )

        $OFS = '-'

        "Array of array as variable:"
        print_argv $cmdArgs

        "`nArray of array as splatted arguments:"
        print_argv @cmdArgs
    }
}

if ($IsWindows) {
    . "$PSScriptRoot/02-arguments.windows.ps1"
}
else {
    . "$PSScriptRoot/02-arguments.linux.ps1"
}
