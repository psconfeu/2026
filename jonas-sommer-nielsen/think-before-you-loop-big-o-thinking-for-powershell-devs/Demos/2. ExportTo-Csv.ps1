

#region Export to CSV in a loop
$users | ForEach-Object {
    $_ | Export-Csv 'C:\github\PSConf.eu2026\talks\big-o-thinking\Demos\users.csv' -NoTypeInformation -Append
}

    #region Big O
        # O(n) - Each user is processed once
    #endregion
#endregion


#region Export to CSV
$users | Export-Csv 'C:\github\PSConf.eu2026\talks\big-o-thinking\Demos\users.csv' -NoTypeInformation 

    #region Big O
        # O(1) - The entire collection is processed in a single operation 
    #endregion
#endregion