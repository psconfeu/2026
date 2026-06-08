# Conclusion: Why Concurrent Collections Matter in PowerShell

Most PowerShell developers are comfortable with arrays, lists, and hashtables.

What is often less understood is what happens when those same structures are used in parallel execution.

That is where subtle and dangerous bugs begin to appear.

---

# What We Learned

## Parallelism changes the execution model

In sequential execution, data access is predictable and linear.

In parallel execution, multiple threads can access and modify the same data at the same time.

This introduces a new class of problem:

> Race conditions and lost updates

---

## The real issue: shared mutable state

The problem is not parallelism itself.

The problem is:

- Multiple threads
- Accessing the same object
- Performing non-atomic operations

Even simple assignments become unsafe when executed concurrently.

---

# The Failure Mode

## Non-thread-safe collections fail silently

When shared collections are used in parallel execution, updates can be lost without any error or warning.

The reason is that operations like “read → modify → write” are not atomic.

Between those steps, another thread can intervene.

---

## What actually happens

A single logical update is broken into multiple steps:

- One thread reads the current value
- Another thread reads the same value
- Both modify independently
- Both write back

The result is that one update overwrites the other.

---

## The dangerous part

There is no exception.

There is no crash.

Only missing or incorrect data.

---

# The Fix: Concurrent Collections

## Thread-safe collections solve the problem internally

Concurrent collections are designed specifically for parallel environments.

They ensure that operations are executed atomically and safely across threads.

Instead of relying on external synchronization, they handle correctness internally.

---

## Example concept: TryAdd

A key operation in concurrent dictionaries is “TryAdd”.

It means:

> Add this key-value pair only if the key does not already exist.

More importantly:

- The check and insert happen as a single atomic operation
- No thread can interrupt this process
- Only one thread succeeds for a given key

---

## What this guarantees

Even if multiple threads attempt to add the same key at the same time:

- One succeeds
- All others fail safely
- No corruption occurs
- No data is overwritten unexpectedly

---

# Why this works

Concurrent collections rely on low-level synchronization techniques such as atomic compare-and-swap operations.

This ensures that critical sections inside the collection cannot be interleaved between threads.

The important shift is:

> You no longer protect the data yourself — the data structure protects itself.

---

# The Trade-Off

## Non-thread-safe collections

- Fast
- Simple
- Unsafe under parallel execution

---

## Concurrent collections

- Slightly more overhead
- Safe under parallel execution
- Predictable and reliable results

---

# When to use concurrent collections

They should be used when:

- Multiple threads access shared data
- Parallel execution is involved
- Data integrity is critical
- You are using runspaces, jobs, or parallel loops

---

# When NOT to use them

They are unnecessary when:

- Execution is single-threaded
- Data is not shared across threads
- You can isolate data per thread instead
- Simplicity is more important than concurrency safety

---

# Mental Model

## Unsafe model

Multiple threads directly modify shared state without coordination, leading to unpredictable outcomes.

---

## Safe model

Multiple threads interact with a collection that enforces atomic operations internally, ensuring consistency.

---

# Key takeaway

Parallelism is not inherently dangerous.

The danger comes from unsafe shared mutation.

---

# Final Thought

Once you stop thinking in terms of “how do I make this faster in parallel”  
and start thinking in terms of “how do I keep this safe in parallel”,

you begin to design systems that scale correctly under load instead of breaking unpredictably.