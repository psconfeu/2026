#Collaps all regions CTRL + k + 0


#region Find dublicate users                  
foreach ($user in $users) {                             # n * (
    $count = 0;                                         # 1
    foreach ($u in $users) {                            # n * (   
        if ($u.Name -eq $user.Name) {                   # 1
            $count++                                    # 1 )
        }   
    }                                                       
    if ($count -gt 1) { $user }                         # 1 )                    
}                                                       # 

    #region big O
        # O( n * (1 + (n * (1 + 1))) + 1 ) => O(n * n) => O(n^2)
        # ~ 10 000 * 10 000 = 100 000 000
    #endregion
#endregion

#region Find duplicates users by building a hashtable
$lookupHash = @{}                                   # 1 - create empty hashtable
foreach ($user in $users) {                         # n * (
    if ($lookupHash.ContainsKey($user.Name)) {      # 1   
        $user                                       # 1
    } else {
        $lookupHash[$user.Name] = $user             # 1 )
    } 
}

    #region big O
        # O(1 + n + 1 + 1 + 1) => O(n)
        # ~ 10 000
    #endregion
#endregion

#region The obvious oneliner
$users | Group-Object Name | Where-Object Count -gt 1 | Sort-Object count | Select-Object -ExpandProperty Group
# O(?) - depending on Powershell version and implementation, but likely O(n) or O(n log n) or even O(n^2) in the worst case
#endregion