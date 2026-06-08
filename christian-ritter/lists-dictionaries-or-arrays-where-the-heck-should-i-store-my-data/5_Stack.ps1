# --------------------------------------
# Stack (LIFO - Last In, First Out)
# --------------------------------------

# A Stack is a last-in, first-out data structure
# Only the top element is accessible at any time
# Used for undo systems, execution contexts, and nested operations

$Stack = [System.Collections.Generic.Stack[string]]::new()


# --------------------------------------
# Push (add items to the top)
# --------------------------------------

$Stack.Push("First")
$Stack.Push("Second")
$Stack.Push("Third")

# Current stack (top is last element pushed)
"Stack state: $($Stack.ToArray() -join ', ')"


# --------------------------------------
# Peek (inspect top without removing)
# --------------------------------------

$nextItem = $Stack.Peek()
"Peek (top item): $nextItem"


# --------------------------------------
# Pop (remove + return top item)
# --------------------------------------

$lastItem = $Stack.Pop()
"Pop (removed): $lastItem"

"Stack after pop: $($Stack.ToArray() -join ', ')"


# --------------------------------------
# Real-world example: Undo system
# --------------------------------------

# Stack naturally models "undo"
# Each action is pushed, undo pops last action

$undoStack = [System.Collections.Generic.Stack[string]]::new()

$undoStack.Push("Typed 'Hello'")
$undoStack.Push("Typed 'Hello World'")
$undoStack.Push("Deleted 'World'")
$undoStack.Push("Formatted text")

"Current state: $($undoStack.ToArray() -join ' | ')"


# Undo last action
$lastAction = $undoStack.Pop()
"UNDO: $lastAction"

"After undo: $($undoStack.ToArray() -join ' | ')"


# --------------------------------------
# Key idea
# --------------------------------------

# Stack = history of actions
# Pop = go back one step
# Push = add new state