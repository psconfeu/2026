#Define the number of Ras Entries to initially allocate to send to the function, must be more than 1 to avoid crashing PowerShell
$initialEntryAllocation = 1

#Define the C# code
$RasEnumEntriesCode = @'
//Certain values are hard coded into Windows, we need these to define the correct amount of memory to allocate
    public static class RasConstants
    {
        public const int MaxEntryName = 256;
        public const int MAX_PATH = 260;
    };

//Define an Enum with the different types of profiles, this could also be a uint
    public enum ProfileType
    {
        REN_User = 0x0,
        REN_AllUsers = 0x1
    };

//This is the data object for a single VPN Profile
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct RasEntryName
    {
        public int structSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxEntryName + 1)]
        public string entryName;
        public ProfileType profileType;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MAX_PATH + 1)]
        public string phonebookLocation;
    };

//This is the system call that will return all the entries in a phonebook
    [DllImport("rasapi32.dll", SetLastError = true, CharSet = CharSet.Auto, ThrowOnUnmappableChar = true)]
    public static extern int RasEnumEntries(
        [In] IntPtr reserved,
        [In] string phonebookLocation,
        [In, Out] IntPtr rasEntryNameArray,
        [In, Out] ref int memorySize,
        [Out] out int rasEntriesCount
    );
'@

#Compile the C# code and load it into the PowerShell environment
Add-Type -MemberDefinition $RasEnumEntriesCode -Name RasAPI -Namespace Pinvoke

#Check for bad allocation settings and throw an error if not acceptable
if ($initialEntryAllocation -lt 1)
{
    throw "At least 1 Ras Name Entry must be allocated to avoid memory access exceptions"
}

#Calculate the size of a single RasEntryName object (should be 1048 bytes)
$RasEntryNameSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][Pinvoke.RasAPI+RasEntryName])

#Define the variable used by RasEnumEntries to return the number of entries available, must be defined before use to enable referencing
$EntityCount = 0

#Create a blank RASEntryName object, used for clearing the allocated memory/setting the data size correctly
$EmptyRasEntry = New-Object Pinvoke.RasAPI+RasEntryName
#Set the structure data size
$EmptyRasEntry.structSize = $RasEntryNameSize

#Directly allocate a block of memory equal to the size of the number of RasEntryName objects being provisioned
$MemoryAllocation = $RasEntryNameSize * $initialEntryAllocation
$ptrInfo = [Runtime.InteropServices.Marshal]::AllocHGlobal($MemoryAllocation)

#Loop through the allocated memory and copy the empty (with structSize set) RasEntryName object over any existing memory
$ptrOffset = $ptrInfo.ToInt64()
for ($i = 0; $i -lt $initialEntryAllocation; $i++)
{
    #Create a new pointer pointing at the current start of the memory for a new object
    $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
    #Copy the empty object into memory
    [System.Runtime.InteropServices.Marshal]::StructureToPtr($EmptyRasEntry, $newIntPtr,$false)
    #Define a new memory pointer
    $ptrOffset = $newIntPtr.ToInt64()
    #Increment the pointer to point at the next entry starting location
    $ptrOffset += $RasEntryNameSize
}

#Make an initial call to the RasEnumEntries function, passing in the phonebook location, the cleared memory and pointers to the MemoryAllocation and EntityCount variables
$Result = [Pinvoke.RasAPI]::RasEnumEntries([System.IntPtr]::Zero, "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", $ptrInfo, [ref] $MemoryAllocation, [ref] $EntityCount)

#Create an empty array to store the fully defined entries after processing
$RasEntries = @()

#Return results should be 0 for completed successfully, 603 for more memory needed. Errors are defined https://learn.microsoft.com/en-us/windows/win32/rras/routing-and-remote-access-error-codes or https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
if ($Result -eq 603)
{
    Write-Warning "There are $EntityCount profiles stored in rasphone.pbk but only $initialEntryAllocation entries were initially allocated, running with correct memory allocation"#

    #Reallocate the memory based on the actually needed memory required
    $ptrInfo = [Runtime.InteropServices.Marshal]::AllocHGlobal($MemoryAllocation)

    #Re-clear the memory
    $ptrOffset = $ptrInfo.ToInt64()
    for ($i = 0; $i -lt $EntityCount; $i++)
    {
        $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
        [system.runtime.interopservices.marshal]::StructureToPtr($EmptyRasEntry, $newIntPtr,$false)
        $ptrOffset = $newIntPtr.ToInt64()
        $ptrOffset += $RasEntryNameSize
    }

    #Re-call the RasEnumEntries function with the updated memory
    $Result = [Pinvoke.RasAPI]::RasEnumEntries([System.IntPtr]::Zero, "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", $ptrInfo, [ref] $MemoryAllocation, [ref] $EntityCount)

    #Throw an error if this still doesn't return correctly
    if ($Result -ne 0)
    {
        throw "Unable to get RasEnumEntries with error code $Result"
    }

    #Copy the memory into dedicated RasEntryName objects and add them to the $RasEntries array for future processing
    $ptrOffset = $ptrInfo.ToInt64()
    for ($i = 0; $i -lt $EntityCount; $i++)
    {
        $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
        $RasEntry = [Runtime.InteropServices.Marshal]::PtrToStructure($newIntPtr, [System.Type][Pinvoke.RasAPI+RasEntryName])
        $RasEntries += $RasEntry
        $ptrOffset = $newIntPtr.ToInt64()
        $ptrOffset += $RasEntryNameSize
    }
}
elseif ($Result -eq 0)
{
    if ($EntityCount -gt 0)
    {
        #Copy the memory into dedicated RasEntryName objects and add them to the $RasEntries array for future processing
        $ptrOffset = $ptrInfo.ToInt64()
        for ($i = 0; $i -lt $EntityCount; $i++)
        {
            $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
            $RasEntry = [Runtime.InteropServices.Marshal]::PtrToStructure($newIntPtr, [System.Type][Pinvoke.RasAPI+RasEntryName])
            $RasEntries += $RasEntry
            $ptrOffset = $newIntPtr.ToInt64()
            $ptrOffset += $RasEntryNameSize
        }
    }
    else
    {
        Write-Output "There are no profiles currently in rasphone.pbk"
    }
}
else
{
    Write-Warning "Something went wrong, error code: $Result"
}

#Loop through all entries and print out the profile name
foreach ($entity in $RasEntries)
{
    Write-Output "Profile Name: $($Entity.entryName)"
}

#Dump the entire object array to the screen
Write-Output "Full Details:"
$RasEntries