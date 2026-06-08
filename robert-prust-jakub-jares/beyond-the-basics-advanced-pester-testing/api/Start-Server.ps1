<#
.SYNOPSIS
    Tiny PowerShell mock API for the PSConfEU module.
.DESCRIPTION
    Pure HttpListener. JSON files in ./json are the "database".
    GET routes only in this revision; POST handlers added in the next step.
#>
[CmdletBinding()]
param(
    [int] $Port = 5000,
    # 'localhost' works without admin on Windows dev. Containers should pass '+'
    # (Linux PowerShell allows it without root-only URL reservation).
    [string] $ListenHost = 'localhost'
)

$ErrorActionPreference = 'Stop'

$dataDir = Join-Path $PSScriptRoot 'json'

function Read-Data { param([string]$Name)
    Get-Content (Join-Path $dataDir "$Name.json") -Raw | ConvertFrom-Json
}

function Write-Json { param($Response, $Object, [int]$Status = 200, [switch]$AsList)
    $Response.StatusCode  = $Status
    $Response.ContentType = 'application/json'
    $json = if ($AsList) {
        if ($null -eq $Object -or @($Object).Count -eq 0) { '[]' }
        else { @($Object) | ConvertTo-Json -Depth 8 -AsArray }
    } else {
        $Object | ConvertTo-Json -Depth 8
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Get-QueryFilter { param([System.Uri]$Url, [string[]]$AllowedKeys)
    if (-not $Url.Query) { return { $true } }
    $pairs = $Url.Query.Substring(1) -split '&' | Where-Object { $_ }
    $clauses = foreach ($pair in $pairs) {
        $k, $v = $pair -split '=', 2
        if ($AllowedKeys -and ($k -notin $AllowedKeys)) { continue }
        $vEsc = $v -replace "'", "''"
        "(`$_.{0} -eq '{1}')" -f $k, $vEsc
    }
    if (-not $clauses) { return { $true } }
    [scriptblock]::Create(($clauses -join ' -and '))
}

function Get-NextId { param([object[]]$Existing, [string]$Prefix)
    $max = 0
    foreach ($e in $Existing) {
        if ($e.id -match "^$Prefix(?<n>\d+)$") {
            $n = [int]$Matches['n']
            if ($n -gt $max) { $max = $n }
        }
    }
    '{0}{1:D3}' -f $Prefix, ($max + 1)
}

function Read-Body { param($Request)
    $sr = [System.IO.StreamReader]::new($Request.InputStream, $Request.ContentEncoding)
    $raw = $sr.ReadToEnd()
    if (-not $raw) { return $null }
    return $raw | ConvertFrom-Json
}

function Save-Data { param([string]$Name, [object[]]$Items)
    $path = Join-Path $dataDir "$Name.json"
    ($Items | ConvertTo-Json -Depth 8) | Set-Content -Path $path -Encoding UTF8
}

function Invoke-Route { param($Request, $Response)
    $path = $Request.Url.AbsolutePath.TrimEnd('/')
    if ($path -eq '') { $path = '/' }
    $method = $Request.HttpMethod

    if ($method -eq 'POST') {
        $body = Read-Body $Request

        switch -Regex ($path) {
            '^/attendees$' {
                if (-not $body.name -or -not $body.email -or -not $body.company) {
                    Write-Json $Response @{ error = 'name, email, and company are required' } 400
                    return $true
                }
                $all = @(Read-Data 'attendees')
                $new = [pscustomobject]@{
                    id      = Get-NextId $all 'A'
                    name    = $body.name
                    email   = $body.email
                    company = $body.company
                }
                $all += $new
                Save-Data 'attendees' $all
                Write-Json $Response $new 201
                return $true
            }
            '^/ratings$' {
                $starsVal = $body.stars -as [int]
                if ($null -eq $starsVal -or $starsVal -lt 1 -or $starsVal -gt 5) {
                    Write-Json $Response @{ error = 'stars must be an integer 1-5' } 400
                    return $true
                }
                $sessions = Read-Data 'sessions'
                if (-not ($sessions | Where-Object id -EQ $body.sessionId)) {
                    Write-Json $Response @{ error = "session $($body.sessionId) not found" } 404
                    return $true
                }
                $all = @(Read-Data 'ratings')
                $new = [pscustomobject]@{
                    id        = Get-NextId $all 'R'
                    sessionId = $body.sessionId
                    stars     = $starsVal
                    comment   = $body.comment
                }
                $all += $new
                Save-Data 'ratings' $all
                Write-Json $Response $new 201
                return $true
            }
        }

        Write-Json $Response @{ error = "no POST route for $path" } 404
        return $true
    }

    if ($method -ne 'GET') {
        Write-Json $Response @{ error = "method $method not allowed" } 405
        return $true
    } 

    switch -Regex ($path) {
        '^/health$' {
            Write-Json $Response @{ status = 'ok' }
            return $true
        }
        '^/sessions$' {
            $filter = Get-QueryFilter $Request.Url @('speakerId','track','day','room','roomId')
            $items = @(Read-Data 'sessions' | Where-Object $filter)
            Write-Json $Response $items -AsList
            return $true
        }
        '^/sessions/(?<id>.+)$' {
            $id = $Matches['id']
            $session = Read-Data 'sessions' | Where-Object { $_.id -eq $id }
            if (-not $session) {
                Write-Json $Response @{ error = "session $id not found" } 404
            } else {
                Write-Json $Response $session
            }
            return $true
        }
        '^/speakers$' {
            $filter = Get-QueryFilter $Request.Url @('name','company')
            $items = @(Read-Data 'speakers' | Where-Object $filter)
            Write-Json $Response $items -AsList
            return $true
        }
        '^/speakers/(?<id>.+)$' {
            $id = $Matches['id']
            $speaker = Read-Data 'speakers' | Where-Object { $_.id -eq $id }
            if (-not $speaker) {
                Write-Json $Response @{ error = "speaker $id not found" } 404
            } else {
                Write-Json $Response $speaker
            }
            return $true
        }
        '^/schedule$' {
            $sessions = Read-Data 'sessions'
            $speakers = Read-Data 'speakers'
            $rooms    = Read-Data 'rooms'
            $joined = $sessions | Sort-Object startTime | ForEach-Object {
                $spk = $speakers | Where-Object id -EQ $_.speakerId | Select-Object -First 1
                $room = $rooms   | Where-Object id -EQ $_.roomId    | Select-Object -First 1
                [pscustomobject]@{
                    id        = $_.id
                    title     = $_.title
                    track     = $_.track
                    day       = $_.day
                    startTime = $_.startTime
                    endTime   = $_.endTime
                    speaker   = $spk.name
                    room      = $room.name
                }
            }
            Write-Json $Response $joined -AsList
            return $true
        }
        '^/attendees$' {
            Write-Json $Response (Read-Data 'attendees') -AsList
            return $true
        }
        '^/ratings/(?<id>.+)$' {
            $id = $Matches['id']
            $rating = Read-Data 'ratings' | Where-Object { $_.id -eq $id }
            if (-not $rating) {
                Write-Json $Response @{ error = "rating $id not found" } 404
            } else {
                Write-Json $Response $rating
            }
            return $true
        }
        '^/ratings$' {
            $filter = Get-QueryFilter $Request.Url @('sessionId')
            Write-Json $Response @(Read-Data 'ratings' | Where-Object $filter) -AsList
            return $true
        }
    }

    Write-Json $Response @{ error = "no route for GET $path" } 404
    return $true
}

function Start-Server {
    $listener = [System.Net.HttpListener]::new()
    $prefix = "http://${ListenHost}:$Port/"
    $listener.Prefixes.Add($prefix)
    try {
        $listener.Start()
        Write-Host "PSConfEU mock API listening on $prefix"
        while ($listener.IsListening) {
            $ctx = $listener.GetContext()
            try {
                $handled = Invoke-Route $ctx.Request $ctx.Response
                if (-not $handled) {
                    Write-Json $ctx.Response @{ error = 'unhandled request' } 500
                }
            }
            catch {
                Write-Host "Handler error: $_"
                try { Write-Json $ctx.Response @{ error = "$_" } 500 } catch {}
            }
            finally {
                try { $ctx.Response.Close() } catch {}
            }
        }
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

Start-Server
