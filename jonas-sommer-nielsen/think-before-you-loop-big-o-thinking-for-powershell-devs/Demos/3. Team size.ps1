# O(n×m) - For each manager
$managers = $users | Where-Object { $_.Id -le 99 }



#region How many users does each manager have? O(n×m)
$managers | ForEach-Object {                                            # m
    $id = $_.Id
    $count = ($users | Where-Object { $_.ManagerId -eq $id }).Count     # n
    [pscustomobject]@{ 
        Manager = $_.Name
        TeamSize = $count 
    }
}
    #region big O
        # O(m x n) -> O(n^2) 
    #endregion
#endregion


#region How many users does each manager have?
$teamSizesHash = @{}                       
foreach ($user in $users) {                 # n
    $teamSizesHash[$user.ManagerId]++           
}

$managers | ForEach-Object {                # m
    [pscustomobject]@{
        Manager  = $_.Name
        TeamSize = $teamSizesHash[$_.Id]
    }
} 

    #region big O
        # O(n) - We process each user once to build the team size dictionary, then we process each manager once to create the report
        # O(n + m) => O(n) since n > m
    #endregion
#endregion