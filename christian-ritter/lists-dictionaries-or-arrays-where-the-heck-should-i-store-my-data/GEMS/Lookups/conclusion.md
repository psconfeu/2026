# Conclusion: Why `Lookup<TKey,TElement>` Deserves a Place in Your Toolbox

Most PowerShell developers know arrays, lists, hashtables, and dictionaries.

Far fewer know about **Lookup**.

That is unfortunate — because it solves a problem the others do not:

## One Key → Many Values

A dictionary gives you:

```text
UPN -> One User
```

A lookup gives you:

```text
Manager -> Many Users
Department -> Many Users
SourceIP -> Many Events
```

That is not a small difference.

That is a different problem space.

---

# What We Learned

## A Lookup is a Read-Only Grouped Index

When we created:

```powershell
$UsersByManager['John']
```

we did not "search" users.

We used a precomputed index.

That distinction matters.

---

## A Dictionary of Lookups Creates Multiple Indexes

By building:

```powershell
$LookUpIndexes.ByManager['Megan']

$LookUpIndexes.ByDepartment['IT']
```

we effectively created multiple query paths over the same dataset.

This is remarkably close to how databases think.

You are no longer storing data.

You are indexing data.

---

# The Big Win: Repeated Queries

Without a lookup:

```powershell
$LargeDataset | Where-Object Department -eq 'HR'
```

Every query scans the entire dataset.

Every time.

O(n)

---

With a lookup:

```powershell
$LargeDatasetByDepartment['HR']
```

The dataset was indexed once.

Then queried in milliseconds.

O(1)-ish retrieval.

That changes everything when:

- Queries are repeated
- Data is large
- Performance matters
- Nested loops start hurting

---

# Performance Results

## Test Dataset

```text
1,000,000 objects
```

---

## Index Creation Cost

| Operation | Time |
|----------|------|
| Build Lookup (ToLookup) | ~16 seconds |

This is the upfront investment.

You pay it once.

---

## Query Performance

| Query Type | Time |
|-----------|------|
| Lookup query | ~30 ms |
| Where-Object | ~20 sec |
| LINQ Where() | ~20 sec |

---

## Relative Difference

| Method | Approx Speed |
|--------|--------------|
| Lookup | 1x baseline |
| Where-Object | ~666x slower |
| LINQ Where | ~666x slower |

That is not a micro-optimization.

That is a different strategy.

---

## Why Query Time Stays Stable

These:

```powershell
$LargeDatasetByDepartment['HR']
$LargeDatasetByDepartment['IT']
$LargeDatasetByDepartment['Security']
```

all return in roughly the same time.

Because the lookup is using an index.

It does not scan the dataset again.

---

## Why Filtering Does Not

These:

```powershell
$LargeDataset | Where-Object Department -eq 'HR'
```

and:

```powershell
$LargeDataset | Where-Object Department -eq 'IT'
```

still require walking the entire dataset.

Every time.

Because filtering is searching.

Lookup is indexed retrieval.

Huge difference.

---

# The Trade-Off

## Lookup has an upfront cost

Build:

```text
16 seconds
```

Query:

```text
30 milliseconds
```

That may sound expensive—

until you query it 100 times.

Or 1000 times.

Then the math changes dramatically.

---

# This is the Pattern

## Don't do this:

```powershell
foreach($manager in $managers){
   $users | Where-Object Manager -eq $manager
}
```

Repeated scans.

Nested iteration.

Pain.

---

## Do this:

```powershell
$ByManager = $Users.ToLookup(...)

foreach($manager in $managers){
   $ByManager[$manager]
}
```

Build once.

Query forever.

---

# When Should You Use Lookup?

Use it when you have:

## One key → many values

Examples:

- Manager → Direct Reports  
- Department → Users  
- SourceIP → Firewall Events  
- EventID → Log Entries  
- Site → Servers  

---

## Repeated filtering against the same dataset

If you are repeatedly doing:

```powershell
Where-Object
```

you may want a lookup.

---

## Large datasets

100 objects?

Probably irrelevant.

1 million objects?

Now it matters.

---

# When NOT To Use It

Do not use a Lookup when:

- You need one key → one value  
  Use a Dictionary.

- Data changes constantly  
  Lookup is read-only.

- You only need one one-off grouping  
  Use `Group-Object`.

- The dataset is tiny  
  Simplicity wins.

---

# Mental Model

## Use Dictionary when:

```text
One key -> One value
```

Examples:

- UPN -> User
- SID -> Object
- GUID -> Device

---

## Use Lookup when:

```text
One key -> Many values
```

Examples:

- Manager -> Users
- Department -> Users
- IP -> Log Entries

---

# Final Thought

Arrays store data.

Lists grow data.

Dictionaries map data.

**Lookups index data.**

That is a fundamentally different idea.

And once you start thinking in indexes instead of repeated filtering,

you start solving problems differently.

And often, much faster.
