[CmdletBinding()]
param (
    [Parameter()]
    [ArgumentCompletions('utf-8', 'passthrough', 'raw')]
    $Encoding = 'utf-8'
)

$stdin = [Console]::OpenStandardInput()
$stdout = [Console]::OpenStandardOutput()

try {
    $buffer = [byte[]]::new(1024)
    $read = $stdin.Read($buffer, 0, $buffer.Length)

    if ($Encoding -eq 'raw') {
        Format-Hex -InputObject $buffer -Count $read
    }
    elseif ($Encoding -eq 'passthrough') {
        $stdout.Write($buffer, 0, $read)
    }
    else {
        [Text.Encoding]::GetEncoding($Encoding).GetString($buffer, 0, $read)
    }
}
finally {
    $stdin.Dispose()
    $stdout.Dispose()
}
