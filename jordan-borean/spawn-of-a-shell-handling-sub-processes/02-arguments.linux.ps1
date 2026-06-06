Demo "Start-Process -ArgumentList on Linux" {
    Description "Shows how Start-Process -ArgumentList works on Linux"

    Code {
        $argList = 'foo', 'arg no quote', '"arg with quote"'

        $procParams = @{
            FilePath = "./argv/linux_argv"
            ArgumentList = $argList
            RedirectStandardOutput = "./output.txt"
            Wait = $true
        }
        Start-Process @procParams
        Get-Content $procParams.RedirectStandardOutput
    }

    Teardown {
        Remove-Item "./output.txt" -ErrorAction Ignore
    }
}

Demo "Start-Process -ArgumentList on Linux as string" {
    Description "Shows how Start-Process -ArgumentList is better off just being a string"

    Code {
        $argString = 'foo arg no quote "arg with quote"'

        $procParams = @{
            FilePath = "./argv/linux_argv"
            ArgumentList = $argString
            RedirectStandardOutput = "./output.txt"
            Wait = $true
        }
        Start-Process @procParams
        Get-Content $procParams.RedirectStandardOutput
    }

    Teardown {
        Remove-Item "./output.txt" -ErrorAction Ignore
    }
}
