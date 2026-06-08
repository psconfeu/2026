# --------------------------------------
# Priority Queue in PowerShell (.NET PriorityQueue)
# --------------------------------------

# A PriorityQueue does NOT process items in insertion order (FIFO)
# Instead, it processes items based on priority ranking

# Lower numeric value = higher priority (default behavior)


$taskQueue = [System.Collections.Generic.PriorityQueue[string, int]]::new()


# --------------------------------------
# Basic usage
# --------------------------------------

$taskQueue.Enqueue("Start Engine and head to PSConfEU", 1)
$taskQueue.Enqueue("Heckle Ben", 3)
$taskQueue.Enqueue("Prep my Sessions", 1)
$taskQueue.Enqueue("Present Sessions", 2)


# --------------------------------------
# Dequeue (highest priority first)
# --------------------------------------

$taskQueue.Dequeue()  # Start Engine...
$taskQueue.Dequeue()  # Prep my Sessions (same priority, insertion order often preserved)


# --------------------------------------
# Internal view (NOT sorted)
# --------------------------------------

# This shows heap structure, not logical order
$taskQueue.UnorderedItems


# --------------------------------------
# Key concept
# --------------------------------------

# PriorityQueue = "What is most important right now?"
# Not "what came first"


# --------------------------------------
# Advanced: custom priority ordering
# --------------------------------------

class PriorityTupleComparer : System.Collections.Generic.IComparer[System.Tuple[int, datetime]] {
    [int] Compare([System.Tuple[int, datetime]] $x, [System.Tuple[int, datetime]] $y) {
        # Compare Priority descending
        if ($x.Item1 -lt $y.Item1) { return -1 }
        elseif ($x.Item1 -gt $y.Item1) { return 1 }

        # If Priority equal, compare Timestamp - Last in first out  (LIFO)
        if ($x.Item2 -gt $y.Item2) { return -1 }
        elseif ($x.Item2 -lt $y.Item2) { return 1 }

        return 0
    }
}


# --------------------------------------
# Advanced queue with custom priority logic
# --------------------------------------

$comparer = [PriorityTupleComparer]::new()
$queue = [System.Collections.Generic.PriorityQueue[object, System.Tuple[int, datetime]]]::new($comparer)
# --------------------------------------
# Enqueue structured tasks
# --------------------------------------

$queue.Enqueue(
    [PSCustomObject]@{ Description="Start Engine and head to PSConfEU" },
    [Tuple]::Create(1, [datetime]"2026-03-20 08:00")
)

$queue.Enqueue(
    [PSCustomObject]@{ Description="Present Sessions" },
    [Tuple]::Create(2, [datetime]"2026-03-22 09:00")
)

$queue.Enqueue(
    [PSCustomObject]@{ Description="Prep my Sessions" },
    [Tuple]::Create(1, [datetime]"2026-03-20 09:00")
)

$queue.Enqueue(
    [PSCustomObject]@{ Description="Heckle Ben" },
    [Tuple]::Create(3, [datetime]"2026-03-19 12:00")
)


# --------------------------------------
# Process in priority order
# --------------------------------------

while ($queue.Count -gt 0) {

    $item = $queue.Dequeue()

    $item.Description
}

