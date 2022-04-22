<#
1. Ensure that "VSS" service is set to Manual or Automatic. If not, set to Manual.
2. Check the current % allocation of disk space on the target drives.
    vssadmin List ShadowStorage
3. If the allocation is less than 10% or missing:
    - Ensure that the the drive has at least 20% free space before allocation to ensure that the drive does not fill up.
        Ex: 
        Drive C is 200GB.
        The current allocation for ShadowStorage is 5%. We need to increase to 10%.
        There is 20GB of space left on the drive.
        Space Allocation for ShadowStorage = 200GB * 0.05 = 10GB
        Available Space Before Allocation = Space Remaining + Current Space Allocation = 20GB + 10GB = 30GB
        Percentage Free Space Before Allocation = 30GB / 200GB = 0.15
        The drive only has 15% free space available before allocation. The drive should be cleaned up before changing the allocation to 10%.
    - Run the command to create/reallocate drive space.
        - If the allocation is totally missing: (will only work on Windows Servers)
            vssadmin Add ShadowStorage /For=<DriveLetter>: /On=<DriveLetter>: /MaxSize=10%
        - If the allocation is not 10%:
            vssadmin Resize ShadowStorage /For=<DriveLetter>: /On=<DriveLetter>: /MaxSize=10%
4. Set the interval to whatever interval the client would like. SentinelOne defaults to 4 hours (240 minutes).
    c:\program files\sentinelone\sentinel agent <version>\sentinelctl.exe configure -p agent.snapshotIntervalMinutes -v <minutes>
#>

<#
.SYNOPSIS
    
.EXAMPLE
    
.PARAMETER -ProvidedUsername
    
.NOTES
    
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$ProvidedUsername
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
##process
#is VSS set to manual? If not, set to manual
$vssServiceStatus = Get-Service -Name VSS | Select-Object -ExpandProperty starttype
if (!($vssServiceStatus -eq 'Manual')){
    Set-Service -Name VSS -StartupType Manual
}
#Being a brat and not listening to Stephen, using CIM instance instead of old vssadmin command. 
#Feels less deprecated and now I have a sweet sweet object instead of having to parse a string array.
#... (I couldn't figure out how to parse the cmd result string effectively.)
$shadowStorage = Get-CIMInstance -ClassName Win32_ShadowStorage
#get data for machine volumes into an object
$volumes = Get-CIMInstance -ClassName Win32_Volume
#find which volume is used by VSS
foreach ($copy in $shadowStorage){
    $matchingVolume = $volumes | Where-Object DeviceID -eq $copy.Volume.DeviceID
}
#get VSS disk capacity
$capacity = $matchingVolume.Capacity
#get VSS disk availability
$availableDiskSpace = $matchingVolume.FreeSpace
#get drive space allocated by VSS in bytes
$allocatedSpace = $ShadowStorage.AllocatedSpace
#get percentage of disk space allocated by VSS
$PercentCapacityAllocated = (($capacity - $allocatedSpace)/$matchingVolume.Capacity)*100
#get avail space before allocation
$avalableSpaceBeforeAllocation = $availableDiskSpace+$allocatedSpace
#get percentage of full drive of available space before allocation
$PercentFreeSpaceBeforeAllocation = $avalableSpaceBeforeAllocation/$capacity*100
#check allocated percentage. needs to be 10%
if($PercentCapacityAllocated -lt 10){
    #if we need to increase allocation, make sure we have the room to do so
    if($PercentFreeSpaceBeforeAllocation -lt 20){
        #not enough space, nope out
        Write-Log -Text 'Insufficient free space to increase allocation Please clean disk and run again' -ERROR
        throw "insufficientFreeSpace"
    }
    #we have enough space, do the needful
    & "vssadmin Add ShadowStorage /For=$matchingVolume.DriveLetter: /On=$matchingVolume.DriveLetter: /MaxSize=10%"
    #TODO: get the version number dynamically with gci
    & "C:\Program Files\SentinelOne\Sentinel agent\sentinelctl.exe configure -p agent.snapshotIntervalMinutes -v 240"
}
