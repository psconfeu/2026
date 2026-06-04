$Timeout = 30 #Seconds

#Define the C# code
$GPUpdateCode = @'
    [DllImport("userenv.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern bool RegisterGPNotification(
        [In] IntPtr Handle,
        [In] bool bMachine //True for Machine Policy, False for User Policy
    );
'@

#Compile the C# code and load it into the PowerShell environment
Add-Type -MemberDefinition $GPUpdateCode -Name UserEnv -Namespace Pinvoke

#Create a new C# Event Object and set it to only reset when we explicitly request it
$gpCallback = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $null)

#Register this Event with the GP Notification system call. This parses in the memory pointer of the callback function
[bool]$EventSucceeded = [Pinvoke.UserEnv]::RegisterGPNotification($gpCallback.SafeWaitHandle.DangerousGetHandle(), $true)

#Check that the registering was successful
if (-NOT $EventSucceeded)
{
    $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastPInvokeError()
    $errorMessage = [System.Runtime.InteropServices.Marshal]::GetLastPInvokeErrorMessage()
    Write-Host "Error Occurred: $errorCode - $errorMessage"
    return
}

#Launch Terminal to run gpudpate /force in another thread
wt.exe

#Set a maximum amount of time to wait, can be infinite
$EndTime = (Get-Date).AddSeconds($Timeout)

#Loop until the timeout is hit
while ($EndTime -gt (Get-Date))
{
    #Blocks the script for 0.5 seconds if the event hasn't been called
    #Returns immediately and true if the event happened
    #Returns after 0.5 seconds false if the event hasn't happened
    if ($gpCallback.WaitOne(500)) #.WaitOne() would block indefinitely
    {
        Write-Output "GP Update Detected!"
        break #Stop checking for Updates after we detect the update
        $gpCallback.Reset() | Out-Null #Resets the trigger to keep looking for events
    }
    Write-Output "Waiting for event"
}