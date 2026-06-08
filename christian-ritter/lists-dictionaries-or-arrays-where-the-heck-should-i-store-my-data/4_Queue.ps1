# --------------------------------------
# Queue in PowerShell (.NET Queue)
# --------------------------------------

# A Queue is a FIFO (First-In, First-Out) collection
# Items are processed in the exact order they are added


# --------------------------------------
# Create a legacy Queue (non-generic)
# --------------------------------------

$myQueue = New-Object System.Collections.Queue

# Enqueue adds items to the back of the queue
$myQueue.Enqueue("First")
$myQueue.Enqueue("Second")
$myQueue.Enqueue("Third")
$myQueue.Enqueue("Fourth")


# --------------------------------------
# Dequeue (consume items)
# --------------------------------------

# Dequeue removes and returns the oldest item (front of queue)

$firstItem = $myQueue.Dequeue()
"Dequeued: $firstItem"

$secondItem = $myQueue.Dequeue()
"Dequeued: $secondItem"


# --------------------------------------
# Inspect remaining items
# --------------------------------------

# Converts queue to array snapshot (does NOT modify queue)
"Current Queue: $($myQueue.ToArray() -join ', ')"

# Peek (look without removing)
$nextItem = $myQueue.Peek()
"Next item (Peek): $nextItem"


# --------------------------------------
# Generic Queue (recommended)
# --------------------------------------

# Strongly typed, modern version
$queueRange = [System.Collections.Generic.Queue[int]]::new([int[]](1..10))

"Queue initialized with range:"
$queueRange.ToArray()


# --------------------------------------
# EnqueueRange simulation (concept)
# --------------------------------------

# Queue does NOT have EnqueueRange()
# Because it models streaming input, not batch mutation

function Add-ToQueue {
    param(
        [System.Collections.Generic.Queue[object]]$Queue,
        [object[]]$Items
    )

    foreach ($item in $Items) {
        $Queue.Enqueue($item)
    }
}


# --------------------------------------
# Real-world example: task processing
# --------------------------------------

# Queue = work pipeline / job buffer / task stream

#region prepping the queue for the example
$NewQueue = [System.Collections.Generic.Queue[string]]::new()

$NewQueue.Enqueue("Task1: Never")
$NewQueue.Enqueue("Task2: Gonna")
$NewQueue.Enqueue("Task3: Give")
$NewQueue.Enqueue("Task4: You")
$NewQueue.Enqueue("Task5: Up")
#endregion


# --------------------------------------
# Correct processing pattern (FIFO worker loop)
# --------------------------------------
foreach($TaskNumber in 1..$NewQueue.count){
    if($TaskNumber -eq 4){
        Write-Host "Stopping process at Task $TaskNumber"
        break
    }else{
        Write-Host "Processing Task $TaskNumber : $($NewQueue.Dequeue().ToString().split(':')[1].Trim())"
    }
}


# --------------------------------------
# Key takeaways
# --------------------------------------

# - Queue = FIFO processing model
# - Enqueue = add work
# - Dequeue = consume work
# - Peek = inspect next item
# - Ideal for pipelines, workers, and job processing systems
#region prepping the queue for the example
$NewQueue = [System.Collections.Generic.Queue[string]]::new()
$NewQueue.Enqueue("Task1: Never")
$NewQueue.Enqueue("Task2: Gonna")
$NewQueue.Enqueue("Task3: Give")
$NewQueue.Enqueue("Task4: You")
$NewQueue.Enqueue("Task5: Up")
#endregion


