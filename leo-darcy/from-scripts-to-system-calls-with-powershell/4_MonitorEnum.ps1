#Define the C# code
$MonitorEnumCode = @'
//Define a delegate function that will be called for every Monitor that EnumDisplayMonitors finds
    public delegate bool MONITORENUMPROC(IntPtr hMonitor, IntPtr hdcMonitor, RECT lprcMonitor, IntPtr dwData);

//Calling this function will call the function passed into lpfnEnum for every Monitor that is connected to the system
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern bool EnumDisplayMonitors(
        [In] IntPtr hdc, //HDC
        [In] IntPtr lprcClip,
        [In] MONITORENUMPROC lpfnEnum, 
        [In] IntPtr dwData //LPARAM
    );

//Define flags that are associated with specific monitors
    [Flags]
    public enum MonitorInfoFlags : uint
    {
        MONITORINFOF_PRIMARY = 0x00000001
    }

//Certain values are hard coded into Windows, we need these to define the correct amount of memory to allocate
    public static class User32Constants
    {
        public const int CCHDEVICENAME = 32;
    }

//Windows defines a rectangle data type used in many ways which in this case defines the shape and size of a Monitor
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto, Pack = 1)]
    public struct RECT
    {
        public CLong left;
        public CLong top;
        public CLong right;
        public CLong bottom;
    }

//Data structure containing key information about the size and position of a Monitor
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct MONITORINFO
    {
        public uint cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public MonitorInfoFlags dwFlags;
    }

//Data structure containing additional information about the size and position of a Monitor. Most cases don't care about the device name
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct MONITORINFOEX
    {
        public uint cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public MonitorInfoFlags dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = User32Constants.CCHDEVICENAME)]
        public string szDevice;
    }

//Simple function to return key statistics about a system
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern int GetSystemMetrics(int nIndex);

//Get the Monitor Info with the device name info
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern bool GetMonitorInfo(
        [In] IntPtr hMonitor,
        [In,Out] ref MONITORINFOEX lpmi
    );

//Get the Monitor Info without the device name info
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern bool GetMonitorInfo(
        [In] IntPtr hMonitor,
        [Out] out MONITORINFO lpmi
    );
'@

#Compile the C# code and load it into the PowerShell environment
Add-Type -MemberDefinition $MonitorEnumCode -Name User32API -Namespace Pinvoke

#Define different Enum options for calling GetSystemMetrics, this is not a complete list
enum Metrics
{
    SM_ARRANGE = 56
    SM_CLEANBOOT = 67
    SM_CMONITORS = 80
    SM_CMOUSEBUTTONS = 43
    SM_CONVERTIBLESLATEMODE = 0x2003
}

#Show the number of Monitors attached to the current system
$NumberOfDisplayMonitors = [Pinvoke.User32API]::GetSystemMetrics([Metrics]::SM_CMONITORS)

Write-Output "Found $($NumberOfDisplayMonitors) Monitors"

#Define variables to hold information from the Enum Process, need to be at the script scope as the Enum functions operate as different script block scopes
$Script:MonitorCount = 0
$Script:MonitorList = @()

#Export the error code and message from Windows if applicable 
function Show-ErrorMessage
{
    param ()
    $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastPInvokeError()
    $errorMessage = [System.Runtime.InteropServices.Marshal]::GetLastPInvokeErrorMessage()
    Write-Host "Error Occurred: $errorCode - $errorMessage"
}

#This function gets called sequentially for every monitor connected to the system 
function Get-MonitorDetails
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IntPtr]
        $hMonitor,
        [Parameter(Mandatory)]
        [System.IntPtr]
        $hdcMonitor,
        [Parameter(Mandatory)]
        [Pinvoke.User32API+RECT]
        $lprcMonitor,
        [Parameter(Mandatory)]
        [System.IntPtr]
        $dwData
    )

    Write-Host "Monitor Handle: $hMonitor" #Must use Write-Host rather than Write-Output as the standard Output stream is lost
    #Create a data object to store information about the monitor
    $Info = New-Object -TypeName Pinvoke.User32API+MONITORINFOEX
    #Define the size so that the function knows which version of the data object is being used
    $Info.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][Pinvoke.User32API+MONITORINFOEX])

    #Request additional information about the monitor based on the hMonitor pointer injected into the function by the call from EnumDisplayMonitors
    $MonitorInfoResult = [Pinvoke.User32API]::GetMonitorInfo($hMonitor, [ref] $info)
    #Keep track of the total monitor count returned
    $Script:MonitorCount = $Script:MonitorCount + 1

    #Handle Errors 
    if (-NOT $MonitorInfoResult)
    {
        Show-ErrorMessage
        return $false #Don't continue enumerating monitors
    }

    #Save the returned Monitor info into the wider script context for future referencing needs
    $Script:MonitorList += $Info

    #Output some info
    Write-Host "Device: $MonitorCount - $($Info.szDevice), Rect: ($($info.rcMonitor.left),$($info.rcMonitor.top),$($info.rcMonitor.right),$($info.rcMonitor.bottom))"

    #Return true otherwise EnumDisplayMonitors believes that the function failed and will stop further enumerations
    return $true
}

function Get-MonitorDetailsSmall
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IntPtr]
        $hMonitor,
        [Parameter(Mandatory)]
        [System.IntPtr]
        $hdcMonitor,
        [Parameter(Mandatory)]
        [Pinvoke.User32API+RECT]
        $lprcMonitor,
        [Parameter(Mandatory)]
        [System.IntPtr]
        $dwData
    )

    Write-Host "Monitor Handle: $hMonitor"
    #Define a different data object with a different memory size
    $Info = New-Object -TypeName Pinvoke.User32API+MONITORINFO
    $Info.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][Pinvoke.User32API+MONITORINFO])

    $MonitorInfoResult = [Pinvoke.User32API]::GetMonitorInfo($hMonitor, [ref] $info)
    $Script:MonitorCount = $Script:MonitorCount + 1

    if (-NOT $MonitorInfoResult)
    {
        Show-ErrorMessage
        return $false #Don't continue enumerating monitors
    }

    $Script:MonitorList += $Info

    #Don't try and use the Device Name as its not on this data structure
    Write-Host "Rect: ($($info.rcMonitor.left),$($info.rcMonitor.top),$($info.rcMonitor.right),$($info.rcMonitor.bottom))"

    return $true
}

#Call the Enumeration and return all information including the device names
$MonitorEnumResult = [Pinvoke.User32API]::EnumDisplayMonitors([System.IntPtr]::Zero, [System.IntPtr]::Zero, (Get-Item Function:\Get-MonitorDetails).ScriptBlock, [System.IntPtr]::Zero)
$MonitorList = $() #Reset Monitor list array to avoid duplicates
#Call the same function but don't request device name information
$MonitorEnumResult = [Pinvoke.User32API]::EnumDisplayMonitors([System.IntPtr]::Zero, [System.IntPtr]::Zero, (Get-Item Function:\Get-MonitorDetailsSmall).ScriptBlock, [System.IntPtr]::Zero)

#Handle Errors
if (-NOT $MonitorEnumResult)
{
    Show-ErrorMessage
}

$MonitorList