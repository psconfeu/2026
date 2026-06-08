# Dictionaries / Hashtables in PowerShell

# --------------------------------------
# 1. Create a dictionary (Hashtable)
# --------------------------------------

$myDictionary = @{
    "Key1" = "Value1"
    "Key2" = "Value2"
    "Key3" = "Value3"
}

# In PowerShell, @{ } creates a Hashtable:
# System.Collections.Hashtable
# It stores key/value pairs and allows fast lookup


# --------------------------------------
# 2. Accessing values
# --------------------------------------

$value1 = $myDictionary["Key1"]
"Value for Key1: $value1"

# PowerShell Hashtables are CASE-INSENSITIVE
$myDictionary["key1"]   # works
$myDictionary["KEY1"]   # works


# --------------------------------------
# 3. Adding / Updating
# --------------------------------------

# Adding new key-value pairs
$myDictionary["Key4"] = "Value4"

# Updating existing key-value pairs (no duplicates!)
$myDictionary["Key2"] = "UpdatedValue2"


# --------------------------------------
# 4. Removing elements
# --------------------------------------

$myDictionary.Remove("Key4")


# --------------------------------------
# 5. Listing / Iterating
# --------------------------------------

"Current Dictionary:"
$myDictionary

# More readable output
$myDictionary.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{
        Key   = $_.Key
        Value = $_.Value
    }
}



# Access keys and values directly
$myDictionary.Keys
$myDictionary.Values


# --------------------------------------
# 6. Checking for keys
# --------------------------------------

if ($myDictionary.ContainsKey("Key3")) {
    "Key3 exists"
}


# --------------------------------------
# 7. Performance characteristics
# --------------------------------------

# Dictionaries are very fast:
# Average: O(1)
# Worst case (hash collisions): O(n)

$LargeDictionary = @{}
for ($i = 1; $i -le 1000000; $i++) {
    $LargeDictionary["Key$i"] = "Value$i"
}

Measure-Command {
    $LargeDictionary.ContainsKey("Key999999")
}

Measure-Command {
    $LargeDictionary.ContainsKey("Key420")
}

# Position does not matter → constant-time lookup (on average)


# --------------------------------------
# 8. Ordering
# --------------------------------------

# Historically unordered
# Modern PowerShell preserves insertion order in practice
# BUT: not guaranteed by Hashtable itself

($LargeDictionary.Values) | Select-Object -First 10


# --------------------------------------
# 9. Ordered Dictionary
# --------------------------------------

$OrderedDictionary = [System.Collections.Specialized.OrderedDictionary]::new()
$OrderedDictionary.Add("Key1", "Value1")
$OrderedDictionary.Add("Key2", "Value2")

$OrderedDictionary

# Easier syntax
$Ordered = [ordered]@{
    "Key1" = "Value1"
    "Key2" = "Value2"
    "Key3" = "Value3"
}
$Ordered


# --------------------------------------
# 10. Generic Dictionary (strong typing)
# --------------------------------------

# Strongly typed dictionary
$dict = [System.Collections.Generic.Dictionary[string,string]]::new()

$dict.Add("Key1", "Value1")

# CASE-SENSITIVE by default!
$dict["key1"]  # would return nothing (key not found)
$dict["Key1"]  # would return "Value1"

# Case-insensitive version
$dictInsensitive = [System.Collections.Generic.Dictionary[string,string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

$dictInsensitive["Key1"] = "Value1"
$dictInsensitive["key1"]  # works


# --------------------------------------
# 11. Type Safety (IMPORTANT)
# --------------------------------------

# Hashtable: NOT type-safe
$ht = @{}
$ht["Count"] = 10
$ht["Count"] = "ten"   # allowed → no error

# Might fail later at runtime
# $ht["Count"] + 5


# Dictionary: type-safe
$typedDict = [System.Collections.Generic.Dictionary[string,int]]::new()

$typedDict["Count"] = 10

try {
    $typedDict["Count"] = "ten"  # 💥 throws immediately
}
catch {
    "Type safety prevented invalid data:"
    $_.Exception.Message
}

# Takeaway:
# Hashtable = flexible
# Dictionary = safe + predictable


# --------------------------------------
# 12. Pre-sizing (performance optimization)
# --------------------------------------

$bigDict = [System.Collections.Generic.Dictionary[string,string]]::new(1000000)
# avoids resizing / rehashing


# --------------------------------------
# 13. Real-world example: lookup table
# --------------------------------------

$countryCodes = @{
    DE = "Germany"
    US = "United States"
    FR = "France"
}

$countryCodes["DE"]


# --------------------------------------
# 15. When NOT to use a dictionary
# --------------------------------------

# - Need guaranteed ordering → use [ordered]
# - Need duplicate values per key → use list/array
# - Need index-based access → use array or List<T>

#region get rid of those squiggly warnings in VSCode
return
$bigDict
#endregion