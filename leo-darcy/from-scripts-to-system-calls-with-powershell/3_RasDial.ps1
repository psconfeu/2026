$profileName = "Basic Auth"

$VPNProfile = $RasEntries | Where-Object entryName -EQ $profileName

if ($null -eq $VPNProfile)
{
    throw "Unable to locate VPN Profile $profileName"
}

$pbkPath = $VPNProfile.phonebookLocation

#Define the C# code
$RasDialCode = @'
//Certain values are hard coded into Windows, we need these to define the correct amount of memory to allocate
    public static class RasConstants
    {
        public const int MaxEntryName = 256;
        public const int MAX_PATH = 260;
        public const int MaxPhoneNumber = 128;
        public const int MaxCallbackNumber = MaxPhoneNumber;
        public const int UNLEN = 256; //lmcons.h
        public const int PWLEN = 256; //lmcons.h
        public const int CNLEN = 15; //lmcons.h
        public const int DNLEN = CNLEN; //lmcons.h
    };

//Defines all the parameters that we can send into the RasDial system call
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct RasDialParams
    {
        public int dwSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxEntryName + 1)]
        public string szEntryName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxPhoneNumber + 1)]
        public string szPhoneNumber;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxCallbackNumber + 1)]
        public string szCallbackNumber;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.UNLEN + 1)]
        public string szUserName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.PWLEN + 1)]
        public string szPassword;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.DNLEN + 1)]
        public string szDomain;
        public uint dwSubEntry;
        public IntPtr dwCallbackId;
        public uint dwIfIndex;
    }

//This is the system call that will start a VPN profile based on the input of the RasDialParams
    [DllImport("rasapi32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern uint RasDial(
        [In] IntPtr rasDialExtensions, //Should be RasDialExtensions
        [In] string lpszPhonebook,
        [In, Out] ref RasDialParams rasDialParams,
        [In] uint notifierVersion,
        [In] IntPtr notifierFunction, //Should be RasDialFunc2
        [Out] out IntPtr hrasconn
    );

//This system call takes a pointer to a connection and terminates the connection
    [DllImport("rasapi32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern uint RasHangUp(
        [In] IntPtr hrasconn
    );
'@

#Compile the C# code and load it into the PowerShell environment
Add-Type -MemberDefinition $RasDialCode -Name RasAPI2 -Namespace Pinvoke

#Create a new RasDial Parameters object
$DialParams = New-Object Pinvoke.RasAPI2+RasDialParams
#Set the Profile Name that we want to Dial
$DialParams.szEntryName = $profileName
$DialParams.szUserName = "RRASUSER"
$DialParams.szPassword = "Don'tUseMSCHAPv2!"
$DialParams.szDomain = "Leo.PSC"
#Calculate the size of the object
$DialParams.dwSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][Pinvoke.RasAPI2+RasDialParams])

#Create an empty pointer to the connection management object
$connectionHandle = [System.IntPtr]::Zero
#Start the VPN Profile. The Connection Handle is populated to allow further operations such as disconnecting the VPN
$rasDialResult = [Pinvoke.RasAPI2]::RasDial([System.IntPtr]::Zero, $pbkPath, [ref] $dialParams, 2, [System.IntPtr]::Zero, [ref] $connectionHandle)

#Check the result of the dial operation
if ($rasDialResult -ne 0)
{
    Write-Output "Connection Result: $rasDialResult" #This is a standard Windows Error Status Code
}
else
{
    Write-Output "Connection Successful, Handle: $connectionHandle"
}

#Terminate the VPN
$rasHangUpResult = [Pinvoke.RasAPI2]::RasHangUp($connectionHandle)

$rasHangUpResult
#TODO Check Connection Status to avoid issues https://learn.microsoft.com/en-us/windows/win32/api/ras/nf-ras-rashangupw#remarks