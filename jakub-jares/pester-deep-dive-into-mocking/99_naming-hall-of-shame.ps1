@(
    @{ Name = '$_____MockCallState';                   Author = 'Jakub Jareš'; Year = 2019; File = 'Mock.ps1:187'           }
    @{ Name = '$___Mock___parameters';                 Author = 'Jakub Jareš'; Year = 2019; File = 'Mock.ps1:238'           }
    @{ Name = '$______isInMockParameterFilter';        Author = 'Jakub Jareš'; Year = 2020; File = 'Mock.ps1:1210'          }
    @{ Name = '$______current';                        Author = 'Jakub Jareš'; Year = 2019; File = 'Mock.ps1:258'           }
    @{ Name = '${P S Cmdlet}';                         Author = 'Dave Wyatt';  Year = 2015; File = 'Mock.ps1:121'           }
    @{ Name = '${R e p o r t S c o p e}';              Author = 'Jakub Jareš'; Year = 2018; File = 'Mock.ps1:1074'          }
    @{ Name = '${Set Dynamic Parameter Variable}';     Author = 'Jakub Jareš'; Year = 2019; File = 'Mock.ps1:1078'          }
    @{ Name = '${Meta data}';                          Author = 'Dave Wyatt';  Year = 2016; File = 'Mock.ps1:1088'          }
    @{ Name = '${M o d u l e N a m e}';                Author = 'Jakub Jareš'; Year = 2018; File = 'Mock.ps1:1090'          }
    @{ Name = '$____Pester';                           Author = 'Jakub Jareš'; Year = 2020; File = 'Pester.Runtime.ps1:391' }
    @{ Name = '$______pester_invoke_block_parameters'; Author = 'Jakub Jareš'; Year = 2019; File = 'Pester.Runtime.ps1:361' }
) | ForEach-Object { [pscustomobject]$_ } | Format-Table -AutoSize
