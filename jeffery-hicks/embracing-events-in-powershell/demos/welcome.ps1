#requires -version 5.1
#requires -module Storage,CimCmdlets

# this is proof of-concept code

<#
Create an Ubuntu-like welcome display

Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.10.60.1-microsoft-standard-WSL2 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Wed Oct 13 08:13:45 EDT 2021

  System load:  0.08               Processes:             8
  Usage of /:   1.5% of 250.98GB   Users logged in:       0
  Memory usage: 6%                 IPv4 address for eth0: 172.22.114.147
  Swap usage:   0%


0 updates can be applied immediately.


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


This message is shown once a day. To disable it please create the
/home/jeff/.hushlogin file.

#>

#the hush file to disable running this script. The file
#doesn't have to have any content. It simply needs to exist.
$hushPath = Join-Path -Path $home -ChildPath ".hushlogin"

# define a temporary tracking file.
$trackPath = Join-Path -path $env:TEMP -ChildPath pswelcome.tmp
<#
Uncomment this code if you want to use a tracking file

#If the file is less than 24 hours old then skip running this script

$AlreadyRun = $False
if (Test-Path -path $trackPath) {
    $f = Get-Item -path $trackPath
    $ts = New-TimeSpan -Start $f.CreationTime -End (Get-Date)
    if ($ts.TotalHours -le 24) {
        $AlreadyRun = $True
    }
}
#>

if ((Test-Path -Path $hushPath) -OR $AlreadyRun) {
    #skip running the welcome code
}
else {
    if ($PSEdition -eq 'Desktop') {
        $psName = "Windows PowerShell"
        $psosbuild = $PSVersionTable.BuildVersion
    }
    else {
        $psName = "PowerShell"
        $psosbuild = $PSVersionTable.os
    }

    #Wed Oct 13 08:13:45 EDT 2021
    $welcomeDate = Get-Date -Format "ddd MMM dd hh:mm:ss"

    #get the timezone
    $tz = Get-Timezone #[System.TimeZone]::CurrentTimeZone
    if ($tz.IsDaylightSavingTime((Get-Date))) {
        $tzNameString = $tz.DaylightName
    }
    else {
        $tzNameString = $tz.StandardName
    }

    #my hack at creating a time zone abbreviation since there is no built-in
    #way that I can find to get this information. This may not work properly
    #for non-US timezones
    $tzName = ($tznamestring.split() | ForEach-Object {$_[0]}) -join ""

    #Get Drive C usage
    $c = Get-Volume -DriveLetter C
    $used = $c.size - $c.SizeRemaining
    $cusage = "{0:p2} of {1:n0}GB" -f ($used / $c.size), ($c.size / 1GB)

    #get network adapter and IP
    #filter out Hyper-V adapters and the Loopback
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.addressState -eq 'preferred' -AND $_.InterfaceAlias -notmatch "vEthernet|Loopback" } -outvariable if).IPAddress

    #only get the properties I need to use for memory information
    $os = Get-CimInstance -ClassName win32_operatingsystem -Property TotalVisibleMemorySize, FreePhysicalMemory
    $memUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
    $memUsage = "{0:p}" -f ($memUsed / $os.TotalVisibleMemorySize)

    #get system performance counters
    $sysPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System -Property Processes, ProcessorQueueLength

    #get pagefile information
    $pagefile = Get-CimInstance -ClassName Win32_PageFileUsage -Property CurrentUsage,AllocatedBaseSize
    $swap = "{0:p}" -f ($pagefile.CurrentUsage/$pagefile.AllocatedBaseSize)

    <#
    A helper function to format the display so that everything aligns properly.
    The HeadLength is the length of the 'header' like 'System load'
    #>

    #This will be the longest string I have to accomodate
    $longest = "IPV4 address for $($if.InterfaceAlias)".length
    function _display {
        param([object]$value,[int]$headlength,[int]$max =$longest)
        $len = ($max - $headlength)+2
        "{0}{1}" -f (' '*$len),$value
    }

    #build the display here-string inserting the calculated variables
    $out = @"

Welcome to $psName $($PSVersionTable.PSVersion) [$psosbuild]

    * Documentation:  https://docs.microsoft.com/powershell/
    * Management:     https://powershellgallery.com
    * Support:        https://powershell.org

System Information as of $welcomeDate $tzName $((Get-Date).year)

    System load:$(_display -value $sysPerf.ProcessorQueueLength -headlength 11)
    Processes:$(_display -value $sysPerf.Processes -headlength 9 )
    Users logged in:$(_display -value $(((quser).count-1)) -headlength 15)
    Usage of C:$(_display -value $cusage -headlength 10)
    Memory Usage:$(_display -value $memUsage -headlength 12 )
    IPV4 address for $($if.InterfaceAlias):$(_display -value $IP -headlength $longest)
    Swap usage:$(_display -value $swap -headlength 10)

    This message is shown once a day. To disable it please create the
$hushPath file.

"@

    Clear-Host
    #display the welcome text and also send it to the temporary tracking file
    $out | Tee-Object -FilePath $trackPath

}