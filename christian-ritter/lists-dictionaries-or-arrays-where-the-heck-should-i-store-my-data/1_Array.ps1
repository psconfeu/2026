# --------------------------------------
# Arrays in PowerShell
# --------------------------------------

# Arrays are fixed-size collections backed by:
# System.Object[]
# They provide fast indexed access but cannot grow in-place

$ThisIsAnArray = @(1, 2, 3, 4, 5)
$ThisIsAlsoAnArray = 1, 2, 3, 4, 5
$ThisIsAlsoAnArrayBuildDifferently = 1..5

# PowerShell arrays are object-based, so they can hold mixed types
$ThisIsAnArrayWithMixedTypes = @(1, "two", 3.0, $true)

# Single-element array syntax
$ThisWayYouCanBuildAnArrayAsWell = ,1


# --------------------------------------
# Array from pipeline output
# --------------------------------------

# One of the most common and efficient ways to build arrays
$ArrayFromPipeline = foreach ($i in 1..5) {
    $i
}


# --------------------------------------
# Array indexing basics
# --------------------------------------

$sample = 1..5

$sample[0]   # first element
$sample[-1]  # last element
$sample[5]

# $sample[10]# would return nothing
# $Sample[10] = 42 would throw an error (arrays cannot grow in-place)


# --------------------------------------
# Extending arrays with +=
# --------------------------------------

# IMPORTANT:
# This does NOT modify the existing array
# It creates a NEW array, copies all elements, and reassigns the variable

$Array = 1..1000

$ArrayIdBefore = Get-ObjectId $Array

$Array += 1001
$Array += 'Strange Value'

$ArrayIdAfter = Get-ObjectId $Array

if ($ArrayIdBefore -ne $ArrayIdAfter) {
    Write-Host "New array created (copy + append)"
}


"Array ID before: $ArrayIdBefore"
"Array ID after: $ArrayIdAfter"

# --------------------------------------
# Performance impact of repeated +=
# --------------------------------------



Measure-Command {
    $ArrayPerformanceTest = @()
    for ($i = 1; $i -le 5000; $i++) {
        $ArrayPerformanceTest += $i
    }
}


# --------------------------------------
# Comparison: Array vs List<T>
# --------------------------------------

# Array: fixed-size, reallocates on every +=
# List<T>: dynamic, uses internal capacity buffer

$List = [System.Collections.Generic.List[int]]::new()
$List.AddRange([int[]](1..1000))

$ListIdBefore = Get-ObjectId $List
$List.Add(1001)
$ListIdAfter = Get-ObjectId $List

if ($ListIdBefore -eq $ListIdAfter) {
    Write-Host "List reused same instance (no reallocation)"
}


# --------------------------------------
# When to use arrays
# --------------------------------------

# Good for:
# - fixed datasets
# - pipeline output
# - small collections
# - memory-predictable structures

# Avoid for:
# - frequent resizing
# - dynamic collections (use List<T> instead)

#region get rid of those squiggly warnings in VSCode
return 
$ThisIsAnArray 
$ThisIsAlsoAnArray
$ThisIsAlsoAnArrayBuildDifferently

# PowerShell arrays are object-based, so they can hold mixed types
$ThisIsAnArrayWithMixedTypes

# Single-element array syntax
$ThisWayYouCanBuildAnArrayAsWell

$ArrayFromPipeline
#endregion