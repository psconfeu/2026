# --------------------------------------
# HashSet in PowerShell (.NET HashSet<T>)
# --------------------------------------

# A HashSet is a collection that enforces uniqueness
# It uses hashing to provide fast membership operations
# Primary use case: "Have I seen this value before?"

$HashSet = [System.Collections.Generic.HashSet[int]]::new()


# --------------------------------------
# Add (enforces uniqueness)
# --------------------------------------

$HashSet.Add(1)  # True  -> added
$HashSet.Add(2)  # True  -> added
$HashSet.Add(1)  # False -> already exists


# --------------------------------------
# Membership checks
# --------------------------------------

$HashSet.Contains(1)  # True
$HashSet.Contains(3)  # False


# --------------------------------------
# Remove elements
# --------------------------------------

$HashSet.Remove(2)  # True
$HashSet.Remove(3)  # False


# --------------------------------------
# Iteration (unordered by design)
# --------------------------------------

foreach ($item in $HashSet) {
    "HashSet item: $item"
}


# --------------------------------------
# Set operations (IMPORTANT: they mutate the set)
# --------------------------------------

$SetA = [System.Collections.Generic.HashSet[int]]::new([int[]](1..5))
$SetB = [System.Collections.Generic.HashSet[int]]::new([int[]](4..8))

# Union (A ∪ B)
$SetUnion = [System.Collections.Generic.HashSet[int]]::new($SetA)
$SetUnion.UnionWith($SetB)
"Union: $($SetUnion -join ', ')"

# Intersection (A ∩ B)
$SetIntersection = [System.Collections.Generic.HashSet[int]]::new($SetA)
$SetIntersection.IntersectWith($SetB)
"Intersection: $($SetIntersection -join ', ')"

# Difference (A - B)
$SetDifference = [System.Collections.Generic.HashSet[int]]::new($SetA)
$SetDifference.ExceptWith($SetB)
"Difference: $($SetDifference -join ', ')"



# --------------------------------------
# Real-world example: deduplication
# --------------------------------------

# Problem: remove duplicates efficiently

$ArrayWithDuplicates = @(
    [PSCustomObject]@{ Name = "Alice"; Age = 30 },
    [PSCustomObject]@{ Name = "Bob"; Age = 25 },
    [PSCustomObject]@{ Name = "Alice"; Age = 30 },
    [PSCustomObject]@{ Name = "Charlie"; Age = 35 }
)

$Seen = [System.Collections.Generic.HashSet[string]]::new()

$UniqueItems = foreach ($item in $ArrayWithDuplicates) {

    # Create a simple "signature" (conceptual key)
    $signature = "$($item.Name)|$($item.Age)"

    if ($Seen.Add($signature)) {
        $item
    }
}

$UniqueItems


# --------------------------------------
# Key idea
# --------------------------------------

# HashSet = "Have I seen this before?"
# List     = "What is at position X?"
# Dictionary = "What is the value for key X?"