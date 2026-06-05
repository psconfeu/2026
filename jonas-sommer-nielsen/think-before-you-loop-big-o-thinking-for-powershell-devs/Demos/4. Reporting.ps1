#region Find all the active users to show how many we have
# $activeUsers = $users | Where IsActive    
$activeUsers = $Users | Where-Object  {         # n
    if ($_.IsActive -eq $true) {                # 1
        $_                                      # 1
    } 
}                

    #region big O
        # O(n)  
        # 10 000 * 1 = 10 000
    #endregion
#endregion


#region build report with string concatenation
# O(n²) - String += copies the ENTIRE string each time

$report = ""
$activeUsers | ForEach-Object {
    $report += "User: $($_.Name) - Email: $($_.Email)`n"
}
    #region big O
        # Depending on the powershell version string concatenation with += can lead to O(n²) complexity 
        # O(n²)
    #endregion
#endregion


#region build report use pipeline 💪
# O(n) - Build the report in one pass

$report2 = ($activeUsers | ForEach-Object {
                "User: $($_.Name) - Email: $($_.Email)"
}) -join "`n"  # Join the array of strings into a single string with newlines    
    #region big O
        # O(n) - We process each active user once to build the report
    #endregion
#endregion 