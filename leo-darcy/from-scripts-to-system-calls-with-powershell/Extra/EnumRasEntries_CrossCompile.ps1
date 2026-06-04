$initialEntryAllocation = 1

$ConstantsCode = @'
    using System; //IntPtr

    public static class RasConstants
    {
        public const int MaxEntryName = 256;
        public const int MAX_PATH = 260;
    }
'@

$ConstantsAssembly = (New-TemporaryFile).FullName.Replace(".tmp",".dll")

$Constants = Add-Type -TypeDefinition $ConstantsCode -OutputAssembly $ConstantsAssembly -PassThru

$EnumCode = @'
    public enum ProfileType
    {
        REN_User = 0x0,
        REN_AllUsers = 0x1
    };
'@

$EnumsAssembly = (New-TemporaryFile).FullName.Replace(".tmp",".dll")
$Enums = Add-Type -TypeDefinition $EnumCode -OutputAssembly $EnumsAssembly -PassThru

$RasEntryNameCode = @"
    using System.Runtime.InteropServices; //MarshalAs

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct RasEntryName
    {
        public int structSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MaxEntryName + 1)]
        public string entryName;
        public ProfileType profileType;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = RasConstants.MAX_PATH + 1)]
        public string phonebookLocation;
    };
"@

Add-Type -TypeDefinition $RasEntryNameCode -ReferencedAssemblies $EnumsAssembly, $ConstantsAssembly

$RasEnumEntriesCode = @'

[DllImport("rasapi32.dll", SetLastError = true,
CharSet = CharSet.Unicode,
ThrowOnUnmappableChar = true)]
 public static extern int RasEnumEntries(
    [In] IntPtr reserved,
    [In] string phonebookLocation,
    [In, Out] IntPtr rasEntryNameArray,
    [In, Out] ref int memorySize,
    [Out] out int rasEntriesCount
);
'@

Add-Type -MemberDefinition $RasEnumEntriesCode -Name RasAPI -Namespace Pinvoke

if ($initialEntryAllocation -lt 1)
{
    throw "At least 1 Ras Name Entry must be allocated to avoid memory access exceptions"
}

$RasEntryNameSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][RasEntryName])

$EntityCount = 0

$EmptyRasEntry = New-Object RasEntryName
$EmptyRasEntry.structSize = $RasEntryNameSize

$ptrInfo = [Runtime.InteropServices.Marshal]::AllocHGlobal($RasEntryNameSize * $initialEntryAllocation)

[Runtime.InteropServices.Marshal]::StructureToPtr($EmptyRasEntry,$ptrInfo, $false)

$MemoryAllocation = $RasEntryNameSize * $initialEntryAllocation
$RasEntries = @()

$Result = [Pinvoke.RasAPI]::RasEnumEntries([System.IntPtr]::Zero, "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", $ptrInfo, [ref] $MemoryAllocation, [ref] $EntityCount)
if ($Result -eq 603)
{
    Write-Warning "There are $EntityCount profiles stored in rasphone.pbk but only $initialEntryAllocation entries were initially allocated, running with correct memory allocation"#

    $ptrInfo = [Runtime.InteropServices.Marshal]::AllocHGlobal($MemoryAllocation)
    $ptrOffset = $ptrInfo.ToInt64()
    for ($i = 0; $i -lt $EntityCount; $i++)
    {
        $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
        [system.runtime.interopservices.marshal]::StructureToPtr($EmptyRasEntry, $newIntPtr,$false)
        $ptrOffset = $newIntPtr.ToInt64()
        $ptrOffset += $RasEntryNameSize
    }

    $Result = [Pinvoke.RasAPI]::RasEnumEntries([System.IntPtr]::Zero, "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk", $ptrInfo, [ref] $MemoryAllocation, [ref] $EntityCount)

    if ($Result -ne 0)
    {
        throw "Unable to get RasEnumEntries with error code $Result"
    }

    $ptrOffset = $ptrInfo.ToInt64()
    for ($i = 0; $i -lt $EntityCount; $i++)
    {
        $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
        $RasEntry = [Runtime.InteropServices.Marshal]::PtrToStructure($newIntPtr, [System.Type][RasEntryName])
        $RasEntries += $RasEntry
        $ptrOffset = $newIntPtr.ToInt64()
        $ptrOffset += $RasEntryNameSize
    }
}
elseif ($Result -eq 0)
{
    if ($EntityCount -gt 0)
    {
        $ptrOffset = $ptrInfo.ToInt64()
        for ($i = 0; $i -lt $EntityCount; $i++)
        {
            $newIntPtr = New-Object system.Intptr -ArgumentList $ptrOffset
            $RasEntry = [Runtime.InteropServices.Marshal]::PtrToStructure($newIntPtr, [System.Type][RasEntryName])
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

foreach ($entity in $RasEntries)
{
    Write-Output "Profile Name: $($Entity.entryName)"
}

Write-Output "Full Details:"
$RasEntries