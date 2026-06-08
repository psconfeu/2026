# --------------------------------------
# Concurrent Collections (Thread-Safe Data Storage)
# --------------------------------------

# Concurrent collections are designed for parallel execution
# They allow multiple threads to safely read and write at the same time
# Without data loss, corruption, or race conditions

# Key idea:
# - Normal collections = NOT thread-safe
# - Concurrent collections = thread-safe by design


# --------------------------------------
# The Problem (Non-thread-safe Hashtable)
# --------------------------------------

# This looks correct, but breaks under parallel execution
# Because multiple threads modify the same shared hashtable

$pool = [runspacefactory]::CreateRunspacePool(1, 50)
$pool.Open()

$dict = @{}   # ❌ NOT thread-safe
$jobs = @()

foreach ($i in 1..2000) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool

    $null = $ps.AddScript({
        param($d, $i)

        # simulate timing overlap between threads
        Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 3)

        # ❌ unsafe write (can be lost due to race condition)
        $d[$i] = $i
    }).AddArgument($dict).AddArgument($i)

    $jobs += [PSCustomObject]@{
        Pipe   = $ps
        Handle = $ps.BeginInvoke()
    }
}

# Wait for all threads to finish
$jobs | ForEach-Object {
    $_.Pipe.EndInvoke($_.Handle)
    $_.Pipe.Dispose()
}

$pool.Close()

"Hashtable count (BROKEN): $($dict.Count)"


# --------------------------------------
# Why this breaks
# --------------------------------------

# The operation:
#   read → modify → write
# is NOT atomic

# Multiple threads can:
# - read the same state
# - overwrite each other
# - silently lose updates

# Result:
# → missing entries
# → inconsistent state
# → nondeterministic behavior


# --------------------------------------
# The Fix (Thread-safe collection)
# --------------------------------------

# ConcurrentDictionary is designed for parallel writes
# It guarantees atomic operations internally

$pool = [runspacefactory]::CreateRunspacePool(1, 50)
$pool.Open()

$dict = [System.Collections.Concurrent.ConcurrentDictionary[int,int]]::new()
$jobs = @()

foreach ($i in 1..2000) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool

    $null = $ps.AddScript({
        param($d, $i)

        Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 3)

        # ✅ safe atomic operation
        $d.TryAdd($i, $i) | Out-Null
    }).AddArgument($dict).AddArgument($i)

    $jobs += [PSCustomObject]@{
        Pipe   = $ps
        Handle = $ps.BeginInvoke()
    }
}

# Wait for completion
$jobs | ForEach-Object {
    $_.Pipe.EndInvoke($_.Handle)
    $_.Pipe.Dispose()
}

$pool.Close()

"ConcurrentDictionary count (SAFE): $($dict.Count)"


# --------------------------------------
# TryAdd (what it actually means)
# --------------------------------------

# TryAdd = "Add this key/value only if the key does NOT already exist"

# Important properties:
# - Atomic operation (no race condition window)
# - Thread-safe by design
# - Only one thread can succeed per key

# Returns:
# - True  → value added
# - False → key already existed


# --------------------------------------
# Key idea
# --------------------------------------

# Parallelism is NOT the problem
# Shared mutable state is

# Safe strategies:
# - Use ConcurrentDictionary / ConcurrentBag
# - Avoid shared state entirely
# - Or isolate data per thread and merge later