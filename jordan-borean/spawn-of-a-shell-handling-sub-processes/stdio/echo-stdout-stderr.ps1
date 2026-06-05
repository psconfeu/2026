$input | ForEach-Object {
    $info = $_ | ConvertFrom-Json

    if ($info.Stream -eq 'stdout') {
        [Console]::Out.Write($info.Value)
    }
    else {
        [Console]::Error.Write($info.Value)
    }
}
