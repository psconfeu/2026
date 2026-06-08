# ======================================
# GEM: The Lookup (The Lost Artifact)
# ======================================

# A Lookup is a precomputed index:
# one key → multiple values

# Instead of searching every time,
# we build a map once and query it instantly later


#region Setup

# LINQ provides ToLookup() for building indexed groupings
Add-Type -AssemblyName System.Linq

#endregion


#region Demo Dataset

# Small dataset for illustrating indexing behavior

$Users = @( 
    [pscustomobject]@{ 
        Name = 'James'; Department = 'IT'; Manager = 'Hailey' 
    }
    [pscustomobject]@{ 
        Name = 'Ben'; Department = 'IT'; Manager = 'Ben' # Self-managed. Because Ben. 
    }
    [pscustomobject]@{ 
        Name = 'Justin'; Department = 'HR'; Manager = 'Gabie' 
    }
    [pscustomobject]@{ 
        Name = 'Christian'; Department = 'HR'; Manager = 'Kids' 
    }
    [pscustomobject]@{ 
        Name = 'Geo'; Department = 'Public Relations'; Manager = 'Gael' 
    }
    [pscustomobject]@{ 
        Name = 'Megan'; Department = 'Public Relations'; Manager = 'Gael' 
    }
    [pscustomobject]@{ 
        Name = 'John'; Department = 'Public Relations'; Manager = 'Gael' 
    }
)

#endregion


#region Build Lookup Index (the "artifact activation")

# This is the expensive step:
# we build a full index in memory

$UsersByManager = [System.Linq.Enumerable]::ToLookup(
    $Users,
    [Func[object,string]]{ param($u) $u.Manager }
)

#endregion


#region Instant Query (the power of the artifact)

# O(1)-style access (hash-based lookup)

$UsersByManager['Gael']

#endregion


#region Multi-Index Strategy

# You can build multiple "artifact views" over the same dataset

$Indexes = @{
    ByManager = [System.Linq.Enumerable]::ToLookup(
        $Users,
        [Func[object,string]]{ param($u) $u.Manager }
    )

    ByDepartment = [System.Linq.Enumerable]::ToLookup(
        $Users,
        [Func[object,string]]{ param($u) $u.Department }
    )
}

$Indexes.ByManager['Gael']
$Indexes.ByDepartment['IT']

#endregion


#region The Tradeoff (IMPORTANT)

# Lookup is NOT free:
# - expensive upfront build
# - higher memory usage
# - only worth it for repeated queries

#endregion


#region Large Dataset (artifact scaling test)

$IDCounter = 0

$LargeDataset = 1..1000000 | ForEach-Object {

    [pscustomobject]@{
        ID         = "ID$($IDCounter++)"
        Department = Get-Random @("IT","HR","Security","Finance","Controlling")
        Manager    = Get-Random @("Megan","John","Sarah","Tom","Anna")
    }
}

$LargeDataset = import-csv .\GEMS\Lookups\LargeDataset.csv

#endregion


#region Lookup vs Scan (core comparison)

# Build once

Measure-Command {
    $ByManager = [System.Linq.Enumerable]::ToLookup(
        $LargeDataset,
        [Func[object,string]]{ param($u) $u.Manager }
    )
}
    $ByManager = [System.Linq.Enumerable]::ToLookup(
        $LargeDataset,
        [Func[object,string]]{ param($u) $u.Manager }
    )
# Fast retrieval (artifact usage)
Measure-Command { $ByManager['Megan'] }


# Brutal scan every time (no artifact)
Measure-Command {
    $LargeDataset | Where-Object Manager -eq 'Megan'
}

#endregion


#region Key Takeaway

# Where-Object  = search the ruins every time
# Lookup        = build the map once, then navigate instantly

#endregion