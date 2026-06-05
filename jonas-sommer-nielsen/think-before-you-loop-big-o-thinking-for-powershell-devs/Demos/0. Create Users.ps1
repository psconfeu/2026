# ============================================
# SETUP: Create a large list of users and a list of emails to search for
# ============================================

$csvNames = 'C:\github\PSConf.eu2026\talks\big-o-thinking\Demos\HeroNames.csv'          # 1

$Names = Import-Csv $csvNames -Delimiter ','                                            # m


#region Create 10,000 users with random names, emails, manager IDs, and active status
$users = 0..9999 | ForEach-Object {                                                     # n * (
    $N = (Get-Random -Minimum 0 -Maximum $Names.Count)                                  # 2
    $S = (Get-Random -Minimum 0 -Maximum $Names.Count)                                  # 2

    [pscustomobject]@{                                                                  # 1
        Id        = $_                                                                  # 1
        # random Firstname and Lastname based on the CSV file
        Name      = "$($Names[$N].Name) $($Names[$S].Surname)"                          # 3
        Email     = "$($Names[$S].Surname).$($Names[$N].Name)@PSConf.eu"                # 3
        ManagerId = Get-Random -Minimum 0 -Maximum 100   # 100 different managers       # 2
        IsActive  = ($_ % 9 -ne 0)                       # ~90% active                  # 3 )
    }
}

    #region big O
        # O(1 + m + n *(17)) => O(m + n) => O(n)
        # ~ 10 000 operations
    #endregion
#endregion


# Show the last few users to verify we have what we expect
$users[-1..2]
