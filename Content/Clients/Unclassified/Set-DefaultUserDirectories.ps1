<#
.SYNOPSIS
    Sets specified user or all users' Library locations to default (Specifically, OS DRIVE\Users\USERNAME\LibraryName. i.e. C:\Users\john.doe\Downloads)
.EXAMPLE
    c:\> Set-DefaultUserDirectories.ps1 -ProvidedUsername john.doe
.PARAMETER -ProvidedUsername
    Optionally set a specific user for which to reset user directories. If no user is specified, all users on the endpoint will be iterated through and reset to their default library locations.
.PARAMETER -MoveDat
    1 or 0, required. if 1 is provided, data will be moved from old library to new.
.NOTES
    In the main loops, uncommenting the Move-FolderData function will also move all files and folders from the intiial library to the new one.
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$ProvidedUsername,
    [Parameter(Mandatory = $false)][switch]$MoveData
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
#functions
function Set-HKURegistryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$SID,
        [Parameter(Mandatory = $true)][string]$RelativeKey,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'Unknown')]
        [string]$PropertyType
    )
    #Ref: https://www.pdq.com/blog/modifying-the-registry-users-powershell/
    # Regex pattern for SIDs
    $PatternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
    # Get Username, SID, and location of ntuser.dat for all users
    $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -eq $SID } |
        Select-Object @{name = $SID; expression = { $_.PSChildName } },
        @{name = 'UserHive'; expression = { "$($_.ProfileImagePath)\ntuser.dat" } },
        @{name = 'Username'; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
    # Get all user SIDs found in HKEY_USERS (ntuser.dat files that are loaded)
    $LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = $SID; expression = { $_.PSChildName } }
    # Get all user hives that are not currently logged in
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = $SID; expression = { $_.InputObject } }, UserHive, Username
    $editedItems = @()
    # Loop through each profile on the machine
    foreach ($item in $ProfileList) {
        # Load User ntuser.dat if it's not already loaded
        IF ($item.SID -in $UnloadedHives.SID) {
            reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
        }
        #####################################################################
        # This is where you can read/modify a users portion of the registry
        $itemPath = "Registry::HKEY_USERS\$($item.SID)\$RelativeKey"
        $foundItem = Get-ItemProperty -Path $itemPath -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        if ($foundItem) {
            # If the entry already exists, then set it.
            Set-ItemProperty -Path $itemPath -Name $Name -Value $Value -ErrorAction SilentlyContinue
        } else {
            # If the entry does not exist, then create it.
            New-ItemProperty -Path $itemPath -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue
        }
        $foundItem = Get-ItemProperty -Path $itemPath -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        if ($foundItem -eq $Value) {
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
function Move-FolderData {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $initialDirectory,
        [Parameter()]
        [string]
        $targetDirectory
    )
    if ($initialDirectory -eq $targetDirectory) {
        Write-Log -Text 'Source and target directories are the same. No files moved.' -Type LOG
        break
    } else {
        #Move-Item -Path $initialDirectory -Destination $targetDirectory
        Copy-Item "$initialDirectory\*" -Destination $targetDirectory -Recurse
        $initialContents = Get-ChildItem -Recurse -Path $initialDirectory
        $targetContents = Get-ChildItem -Recurse -Path $targetDirectory
        $copyResults = Compare-Object $initialContents $targetContents -Property Name
        if (!$copyResults) {
            Write-Log -Text "All data moved from $initialDirectory to $targetDirectory." Type LOG
            Remove-Item $initialDirectory -Force -Recurse
        } else {
            Write-Log -Text 'Some items not copied.' -Type ERROR
            Write-Log -Text $copyResults -Type ERROR
        }
    }
}
function Set-AllProfileFolder {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $sid,
        [Parameter()]
        [string]
        $userProfileDirectory
    )
    $shellFolderKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'My Video' -SID $sid -Value "$userProfileDirectory\Videos" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'Desktop' -SID $sid -Value "$userProfileDirectory\Desktop" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'My Pictures' -SID $sid -Value "$userProfileDirectory\Pictures" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'My Music' -SID $sid -Value "$userProfileDirectory\Music" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name '{374DE290-123F-4565-9164-39C4925E467B}' -SID $sid -Value "$userProfileDirectory\Downloads" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'Personal' -SID $sid -Value "$userProfileDirectory\Documents" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'AppData' -SID $sid -Value "$userProfileDirectory\Application Data" -PropertyType DWORD -ErrorAction SilentlyContinue
    Set-HKURegistryEntry -RelativeKey $shellFolderKey -Name 'Favorites' -SID $sid -Value "$userProfileDirectory\Favorites" -PropertyType DWORD -ErrorAction SilentlyContinue
}
$patternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
$profileFolderNames = @('My Video', 'Desktop', 'My Pictures', 'My Music', '{374DE290-123F-4565-9164-39C4925E467B}', 'Personal')
$profileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } |
    Select-Object @{name = $SID; expression = { $_.PSChildName } },
    @{name = 'UserHive'; expression = { "$($_.ProfileImagePath)\ntuser.dat" } },
    @{name = 'Username'; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } },
    ProfileImagePath
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = $SID; expression = { $_.PSChildName } }
if ($LoadedHives) {
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name = $SID; expression = { $_.InputObject } }, UserHive, Username, ProfileImagePath
} else {
    $UnloadedHives = $ProfileList
}
if (!($ProvidedUsername)) {
    foreach ($profile in $profileList Where-Object  {
        IF ($profile.SID -in $UnloadedHives.SID) {
            reg load HKU\$($profile.SID) $($profile.UserHive) | Out-Null
        }
        $currentShellFolders = Get-ItemProperty -Path "Registry::HKEY_USERS\$($profile.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        if ($profile.SID -in $UnloadedHives.SID) {
            ### Garbage collection and closing of ntuser.dat ###
            [gc]::Collect()
            reg unload HKU\$($profile.SID) | Out-Null
        }
        Set-AllProfileFolder -sid $profile.SID -userProfileDirectory $profile.ProfileImagePath
        if ($MoveData
        ) {
            foreach ($folder in $profileFolderNames) {
                $previousShellFolderPath = $currentShellFolders.$folder
                $targetFolder = $null
                switch ($folder) {
                    'My Video' { $targetFolder = 'Videos' }
                    'Desktop' { $targetFolder = 'Desktop' }
                    '{374DE290-123F-4565-9164-39C4925E467B}' { $targetFolder = 'Downloads' }
                    'Personal' { $targetFolder = 'Documents' }
                    'My Music' { $targetFolder = 'Music' }
                    'My Pictures' { $targetFolder = 'Pictures' }
                    Default {}
                }
                Move-FolderData -initialDirectory $previousShellFolderPath -targetDirectory "$($profile.ProfileImagePath)\$targetFolder"
            }
        }
    }
} else {
    foreach ($profile in $profileList) {
        IF ($profile.SID -in $UnloadedHives.SID) {
            reg load HKU\$($profile.SID) $($profile.UserHive) | Out-Null
        }
        $currentShellFolders = Get-ItemProperty -Path "Registry::HKEY_USERS\$($profile.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        if ($profile.SID -in $UnloadedHives.SID) {
            ### Garbage collection and closing of ntuser.dat ###
            [gc]::Collect()
            reg unload HKU\$($profile.SID) | Out-Null
        }
        Set-AllProfileFolder -sid $profile.SID -userProfileDirectory $profile.ProfileImagePath
        if ($MoveData
        ) {
            foreach ($folder in $profileFolderNames) {
                $previousShellFolderPath = $currentShellFolders.$folder
                $targetFolder = $null
                switch ($folder) {
                    'My Video' { $targetFolder = 'Videos' }
                    'Desktop' { $targetFolder = 'Desktop' }
                    '{374DE290-123F-4565-9164-39C4925E467B}' { $targetFolder = 'Downloads' }
                    'Personal' { $targetFolder = 'Documents' }
                    'My Music' { $targetFolder = 'Music' }
                    'My Pictures' { $targetFolder = 'Pictures' }
                    Default {}
                }
                Move-FolderData -initialDirectory $previousShellFolderPath -targetDirectory "$($profile.ProfileImagePath)\$targetFolder"
            }
        }
    }
}