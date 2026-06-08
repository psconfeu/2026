# --------------------------------------
# ArrayList (LEGACY - DO NOT USE)
# --------------------------------------

# ArrayList is a legacy non-generic collection
# It exists for backward compatibility only
# It stores everything as object → no type safety

$ArrayList = New-Object System.Collections.ArrayList

# AddRange adds multiple elements
$ArrayList.AddRange(1..1000)


# --------------------------------------
# Important behavior: Add() return value
# --------------------------------------

# ArrayList.Add() returns the index where the item was inserted
# This can pollute pipeline output if not suppressed

$ArrayList.Add(1001) | Out-Null


# --------------------------------------
# Demonstrating reference behavior
# --------------------------------------

$ArrayListIdBefore = Get-ObjectId $ArrayList
$ArrayList.Add(1002)
$ArrayListIdAfter = Get-ObjectId $ArrayList

$ArrayListIdBefore -eq $ArrayListIdAfter  # true: same instance, modified in-place

# ArrayList grows in-place (no new object created)
# It modifies internal storage, not the reference itself


# --------------------------------------
# Why ArrayList is dangerous
# --------------------------------------

# 1. Not type safe
$ArrayList.Add("This breaks type expectations") | Out-Null

# 2. Can pollute pipeline output
function New-ArrayListSample {
    $ArrayList.Add('1337')  # returns index (not suppressed)
    return [PSCustomObject]@{
        Name  = 'Sample'
        Value = 42
    }
}

$Result = New-ArrayListSample
$Result
$Result.GetType()


# Fixed version (suppressed output)
function New-ArrayListSampleFixed {
    $ArrayList.Add('1337') | Out-Null
    return [PSCustomObject]@{
        Name  = 'Sample'
        Value = 42
    }
}

$ResultFixed = New-ArrayListSampleFixed
$ResultFixed
$ResultFixed.GetType()


# --------------------------------------
# Generic Lists (RECOMMENDED)
# --------------------------------------

# List<T> is a strongly typed, dynamically resizing collection
# It replaces ArrayList in modern PowerShell / .NET

$List = New-Object System.Collections.Generic.List[object]

$List.AddRange([int[]](1..1000))
$List.Add(1337)

# Type safety: this will fail immediately
$List.Add("This is a string")


# --------------------------------------
# Capacity vs Count
# --------------------------------------

# Capacity = allocated internal buffer
# Count    = actual number of elements

$List.Capacity
$List.Count


# Adding more elements
$List.AddRange([int[]](1..5))
$List.Capacity


# Exceeding capacity triggers resize (usually doubling strategy)
$List.AddRange([int[]](1..2000))
$List.Capacity


# --------------------------------------
# Pre-setting capacity
# --------------------------------------

$ListWithCapacity = New-Object System.Collections.Generic.List[int](3)

$ListWithCapacity.Capacity
$ListWithCapacity.AddRange([int[]](1..5))

# Capacity is not a hard limit
# It will grow automatically if needed


# --------------------------------------
# Reference behavior
# --------------------------------------

$SimpleGenericList = New-Object System.Collections.Generic.List[string]

$SimpleGenericList.Add("A")

# Assignment copies reference (NOT data)
$AssignedByReference = $SimpleGenericList
$AssignedByReference.Add("B")

# Both variables point to same object
$SimpleGenericList[-1]


# --------------------------------------
# Creating a real copy
# --------------------------------------

$AnotherGenericList = New-Object System.Collections.Generic.List[string]
$AnotherGenericList.Add("A")

$JustACopy = [System.Collections.Generic.List[string]]::new($AnotherGenericList)
$JustACopy.Add("B")

# Original remains unchanged
$AnotherGenericList[-1]


# --------------------------------------
# List slicing
# --------------------------------------

$AList = New-Object System.Collections.Generic.List[int]
$AList.AddRange([int[]](1..10))

# Returns a NEW list (copy)
$AList.Slice(2, 5)


# --------------------------------------
# When to use Lists
# --------------------------------------

# - Dynamic collections
# - Frequent additions/removals
# - Strong typing required
# - Performance-sensitive scenarios

# Avoid:
# - simple fixed datasets (use arrays)
# - one-off pipelines (use arrays)