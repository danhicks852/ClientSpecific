#region template
<#
.SYNOPSIS
    Sets Personal OneDrive to hidden in Explorer for all users on an endpoint.
    users are prevented from setting up a sync relationship for their personal OneDrive account.
    Users who are already syncing their personal OneDrive when you enable this
    setting aren't able to continue syncing (they receive a message that syncing has stopped),
    but any files synced to the computer remain on the computer.
.EXAMPLE
    How to run the script
    c:\> Disable-PersonalOneDrive.ps1
.NOTES
    Written by Dan Hicks @ ProVal Tech for Groff
#>
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
#endregion template
function Set-HKURegistryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$SID,
        [Parameter(Mandatory = $true)][string]$RelativeKey,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'Unknown')]
        [string]$PropertyType
    )
    #Ref: https://www.pdq.com/blog/modifying-the-registry-users-powershell/
    # Regex pattern for SIDs
    $PatternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
    # Get Username, SID, and location of ntuser.dat for all users
    $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -eq $SID } |
        Select-Object @{name = 'SID'; expression = { $_.PSChildName } },
        @{name = 'UserHive'; expression = { "$($_.ProfileImagePath)\ntuser.dat" } },
        @{name = 'Username'; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
    # Get all user SIDs found in HKEY_USERS (ntuser.dat files that are loaded)
    $LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = 'SID'; expression = { $_.PSChildName } }
    # Get all user hives that are not currently logged in
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = 'SID'; expression = { $_.InputObject } }, UserHive, Username
    $editedItems = @()
    # Loop through each profile on the machine
    foreach ($item in $ProfileList) {
        # Load User ntuser.dat if it's not already loaded
        IF ($item.SID -in $UnloadedHives.SID) {
            reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
        }
        #####################################################################
        # This is where you can read/modify a users portion of the registry
        New-Item  -Path "Registry::HKEY_USERS\$($item.SID)\SOFTWARE\Policies\Microsoft\" -Name 'OneDrive'
        $itemPath = "Registry::HKEY_USERS\$($item.SID)\$RelativeKey"
        $foundItem = Get-ItemProperty -Path $itemPath -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        if ($foundItem) {
            # If the entry already exists, then set it.
            Set-ItemProperty -Path $itemPath -Name $Name -Value $Value -Type $PropertyType -ErrorAction SilentlyContinue
        } else {
            # If the entry does not exist, then create it.
            New-ItemProperty -Path $itemPath -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue
        }
        $foundItem = Get-ItemProperty -Path $itemPath -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        if (($foundItem -join ',') -eq ($Value -join ',')) {
            $editedItems += Get-ItemProperty -Path $itemPath -Name $Name
        } else {
            Write-Log -Text "Failed to set the requested registry entry: $($Error[0].Exception.Message)" -Type ERROR
            return $null
        }
        #####################################################################
        # Unload ntuser.dat
        if ($item.SID -in $UnloadedHives.SID) {
            ### Garbage collection and closing of ntuser.dat ###
            [gc]::Collect()
            reg unload HKU\$($Item.SID) | Out-Null
        }
    }
    return $editedItems
}

$patternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
$profileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } |
    Select-Object @{name = 'SID'; expression = { $_.PSChildName } },
    @{name = 'UserHive'; expression = { "$($_.ProfileImagePath)\ntuser.dat" } },
    @{name = 'Username'; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } },
    ProfileImagePath
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = 'SID'; expression = { $_.PSChildName } }
if ($LoadedHives) {
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = 'SID'; expression = { $_.InputObject } }, UserHive, Username, ProfileImagePath
} else {
    $UnloadedHives = $ProfileList
}
foreach ($profile in $profileList) {
    IF ($profile.SID -in $UnloadedHives.SID) {
        reg load HKU\$($profile.SID) $($profile.UserHive) | Out-Null
    }
    if ($profile.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($profile.SID) | Out-Null
    }

    Set-HKURegistryEntry -RelativeKey 'SOFTWARE\Policies\Microsoft\OneDrive' -Name 'DisablePersonalSync' -SID $profile.sid -Value '00000001' -PropertyType DWORD -ErrorAction SilentlyContinue
}
