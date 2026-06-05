Demo "Windows mode escaping" {
    Description "PowerShell 7.3+ Windows mode argument escaping"

    Code {
        $spaceArgVar = 'space arg var'
        $jsonArg = '{"key": "value"}'
        $complexQuotingArg = 'Test \" ''value'' "'

        ./argv/win_argv.exe 'space arg literal' $spaceArgVar $jsonArg $complexQuotingArg
    }
}

Demo "Standard mode escaping normal" {
    Description "Standard mode escaping works like Windows mode normally"

    Code {
        $spaceArgVar = 'space arg var'
        $jsonArg = '{"key": "value"}'
        $complexQuotingArg = 'Test \" ''value'' "'

        $PSNativeCommandArgumentPassing = 'Standard'
        ./argv/win_argv.exe 'space arg literal' $spaceArgVar $jsonArg $complexQuotingArg
    }
}

Demo "Legacy mode escaping" {
    Description "WinPS/Legacy mode behaviour sucks"

    Code {
        $spaceArgVar = 'space arg var'
        $jsonArg = '{"key": "value"}'
        $complexQuotingArg = 'Test \" ''value'' "'

        $PSNativeCommandArgumentPassing = 'Legacy'
        ./argv/win_argv.exe 'space arg literal' $spaceArgVar $jsonArg $complexQuotingArg
    }
}

Demo "Escaping JSON strings in legacy mode" {
    Description "Using regex to escape an argument more like Standard mode in WinPS/Legacy"

    Code {
        $jsonArg = '{"key": "value"}'

        $PSNativeCommandArgumentPassing = 'Legacy'

        ./argv/win_argv.exe $jsonArg

        ./argv/win_argv.exe ($jsonArg -replace '"', '\"')
    }
}

Demo "Windows mode escaping special executable name" {
    Description "PowerShell 7.3+ Windows mode argument escaping with special executable name"

    Setup {
        Copy-Item ./argv/win_argv.exe -Destination ./argv/cmd.exe
    }

    Code {
        $spaceArgVar = 'space arg var'
        $jsonArg = '{"key": "value"}'
        $complexQuotingArg = 'Test \" ''value'' "'

        ./argv/cmd.exe 'space arg literal' $spaceArgVar $jsonArg $complexQuotingArg
    }

    Teardown {
        Remove-Item ./argv/cmd.exe -ErrorAction Ignore
    }
}

Demo "Standard mode ignores the special exe names on Windows" {
    Description "Standard mode escaping always uses the newer escaping method even for special executable names"

    Setup {
        Copy-Item ./argv/win_argv.exe -Destination ./argv/cmd.exe
    }

    Code {
        $spaceArgVar = 'space arg var'
        $jsonArg = '{"key": "value"}'
        $complexQuotingArg = 'Test \" ''value'' "'

        $PSNativeCommandArgumentPassing = 'Standard'
        ./argv/cmd.exe 'space arg literal' $spaceArgVar $jsonArg $complexQuotingArg
    }

    Teardown {
        Remove-Item ./argv/cmd.exe -ErrorAction Ignore
    }
}

Demo "Stop processing token" {
    Description "The stop processing token --% takes a literal value and only expands env vars"

    Code {
        $env:_MyEnv = "value abc"
        $someVar = 'foo'

        $PSNativeCommandArgumentPassing = 'Legacy'
        ./argv/win_argv.exe --% literal "test" "double quotes" 'single quotes' $someVar %InvalidEnv% %_MyEnv%
    }

    Teardown {
        $env:_MyEnv = $null
    }
}

Demo "Stop processing token with Windows/Standard mode" {
    Description "The stop processing token --% does not work well with the new Windows/Standard modes"

    Code {
        $env:_MyEnv = "value abc"
        $someVar = 'foo'

        ./argv/win_argv.exe --% literal "test" "double quotes" 'single quotes' $someVar %InvalidEnv% %_MyEnv%
    }

    Teardown {
        $env:_MyEnv = $null
    }
}

Demo "Splatting with stop processing" {
    Description "In Legacy mode you can abuse splatting with stop processing for supporting vars"

    Code {
        $someVar = 'foo'
        $otherVar = 'bar baz'

        $PSNativeCommandArgumentPassing = 'Legacy'
        ./argv/win_argv.exe --% $someVar $otherVar

        $cmdArgs = @(
            '--%'
            $someVar
            $otherVar
        )
        ./argv/win_argv.exe @cmdArgs
    }
}
