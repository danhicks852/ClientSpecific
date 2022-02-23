<#
.SYNOPSIS
    Ensures that the screen saver settings are enabled and set to the specified timeout.
.EXAMPLE
    PS C:\> Protect-Screenlock.ps1 -Timeout 1200
    Ensures that all users that have logged into the machine prior will have a screen saver active, protected, and with a maximum timeout of 1200 seconds.
.EXAMPLE
    PS C:\> Protect-Screenlock.ps1 -Timeout 1200 -DomainException
    If the machine is part of a domain, then no configuration changes will be made, and instead if any configurations are out of scope, then a GPRESULT will be run and placed in the same directory as the script.
.PARAMETER Timeout
    The maximum timeout value for the screen saver. Defaults to 900.
.PARAMETER DomainException
    Set to run a GPRESULT instead of making configuration changes when a machine is part of a domain.
.OUTPUTS
    .\Protect-ScreenLock-log.txt
    .\Protect-ScreenLock-data.txt
    .\Protect-ScreenLock-error.txt
    .\gpresult_computer.html
    .\gpresult_user.html
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)][int]$Timeout = 900,
    [Parameter(Mandatory=$false)][switch]$DomainException
)
### Bootstrap ###
if(-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
    Update-PowerShell
    if($powershellUpgraded) { return }
    if($powershellOutdated) { return }
} else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}

### Process ###
function Get-HKURegistryEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$RelativeKey,
        [Parameter(Mandatory=$true)][string]$Name
    )
    #Ref: https://www.pdq.com/blog/modifying-the-registry-users-powershell/
    # Regex pattern for SIDs
    $PatternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
    
    # Get Username, SID, and location of ntuser.dat for all users
    $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | 
        Select-Object   @{name="SID";expression={$_.PSChildName}}, 
                        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                        @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
    
    # Get all user SIDs found in HKEY_USERS (ntuser.dat files that are loaded)
    $LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object {$_.PSChildname -match $PatternSID} | Select-Object @{name="SID";expression={$_.PSChildName}}
    
    # Get all user hives that are not currently logged in
    if($LoadedHives) {
        $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username
    } else {
        $UnloadedHives = $ProfileList
    }
    
    $foundItems = @()
    # Loop through each profile on the machine
    foreach ($item in $ProfileList) {
        # Load User ntuser.dat if it's not already loaded
        IF ($item.SID -in $UnloadedHives.SID) {
            reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
        }
        #####################################################################
        # This is where you can read/modify a users portion of the registry 
        $foundItem = Get-ItemProperty -Path Registry::HKEY_USERS\$($item.SID)\$RelativeKey -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        $foundItems += [PSCustomObject]@{
            Username = $item.Username
            SID = $item.SID
            Path = Get-Item -Path Registry::HKEY_USERS\$($item.SID)\$RelativeKey -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
            Name = $Name
            Value = $foundItem
            # Value = if($foundItem) { $foundItem -join "," } else { $foundItem }
        }
        #####################################################################
        # Unload ntuser.dat        
        if ($item.SID -in $UnloadedHives.SID) {
            ### Garbage collection and closing of ntuser.dat ###
            [gc]::Collect()
            reg unload HKU\$($Item.SID) | Out-Null
        }
    }
    return $foundItems
}

function Set-HKURegistryEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$SID,
        [Parameter(Mandatory=$true)][string]$RelativeKey,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value,
        [Parameter(Mandatory=$true)]
        [ValidateSet("String","ExpandString","Binary","DWord","MultiString","QWord","Unknown")]
        [string]$PropertyType
    )
    #Ref: https://www.pdq.com/blog/modifying-the-registry-users-powershell/
    # Regex pattern for SIDs
    $PatternSID = '((S-1-5-21)|(S-1-12-1))-\d+-\d+\-\d+\-\d+$'
    
    # Get Username, SID, and location of ntuser.dat for all users
    $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -eq $SID} | 
        Select-Object   @{name="SID";expression={$_.PSChildName}}, 
                        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                        @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
    
    # Get all user SIDs found in HKEY_USERS (ntuser.dat files that are loaded)
    $LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object {$_.PSChildname -match $PatternSID} | Select-Object @{name="SID";expression={$_.PSChildName}}
    
    # Get all user hives that are not currently logged in
    $UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username
    
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
        if($foundItem) {
            # If the entry already exists, then set it.
            Set-ItemProperty -Path $itemPath -Name $Name -Value $Value -ErrorAction SilentlyContinue
        } else {
            # If the entry does not exist, then create it.
            New-ItemProperty -Path $itemPath -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction SilentlyContinue
        }
        $foundItem = Get-ItemProperty -Path $itemPath -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
        if($foundItem -eq $Value) {
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

$domainExceptionActive = $DomainException -and $(Get-WmiObject -Class win32_computersystem | Select-Object -ExpandProperty PartOfDomain)
$osVersion = [System.Environment]::OSVersion.Version.Major
$reportPathComputer = "$workingPath\gpresult_computer.html"
$reportPathUser = "$workingPath\gpresult_user.html"
Remove-Item -Path $reportPathComputer -Force -ErrorAction SilentlyContinue
Remove-Item -Path $reportPathUser -Force -ErrorAction SilentlyContinue

if($osVersion -ge 10) {
    $rootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $valueName = "InactivityTimeoutSecs"
    Write-Log -Text "Checking $($rootPath):$valueName..."
    $GPOInactivityTimeoutSecs = Get-ItemProperty -Path $rootPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
    if((-not $GPOInactivityTimeoutSecs) -or ($GPOInactivityTimeoutSecs -gt $Timeout)) {
        Write-Log -Text "$($rootPath):$valueName needs configuration."
        if($domainExceptionActive) {
            Write-Log -Text "Domain exception active. No configuration changes will be made. Running GPRESULT."
            gpresult /SCOPE COMPUTER /H $reportPathComputer /F
        } else {
            Write-Log -Text "Domain exception is not active. Running configuration update." -Type LOG
            if(-not $GPOInactivityTimeoutSecs) {
                New-ItemProperty -Path $rootPath -Name $valueName -PropertyType DWord -Value $Timeout
            } else {
                Set-ItemProperty -Path $rootPath -Name $valueName -Value $Timeout
            }
            $GPOInactivityTimeoutSecs = Get-ItemProperty -Path $rootPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName
            if((-not $GPOInactivityTimeoutSecs) -or ($GPOInactivityTimeoutSecs -gt $Timeout)) {
                Write-Log -Text "Failed to set regsitry settings. Manual intervention required." -Type ERROR
            } else {
                Write-Log -Text "Registry settings set successfully." -Type DATA
            }
        }
    } else {
        Write-Log -Text "$($rootPath):$valueName is within Timeout parameter."
        Write-Log -Text "Timeout Parameter: $Timeout"
        Write-Log -Text "Current Registry Setting: $GPOInactivityTimeoutSecs"
    }
} else {
    $rootKeyLocal = "Control Panel\Desktop"
    $rootKeyGP = "Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    Write-Log -Text "Checking HKEY_USERS\<USERSID>\... for screensaver settings."
    $entryNames = "ScreenSaveActive", "ScreenSaverIsSecure", "ScreenSaveTimeOut", "SCRNSAVE.EXE"
    $SSAValue = 1
    $SSISValue = 1
    $SSTOValue = $Timeout
    $SSEXEValue = "C:\WINDOWS\System32\scrnsave.scr"
    $screensavers = Get-ChildItem -Path "$($env:windir)\System32\*.scr" | Select-Object -ExpandProperty FullName
    $gpresultRequested = $false
    $entries = @()
    foreach ($entryName in $entryNames) {
        $entries = @()
        $entries += Get-HKURegistryEntries -RelativeKey $rootKeyLocal -Name $entryName
        $entries += Get-HKURegistryEntries -RelativeKey $rootKeyGP -Name $entryName
        $sids = @($entries | Select-Object -ExpandProperty SID -Unique)
        switch ($entryName) {
            "ScreenSaveActive" { 
                foreach($sid in $sids) {
                    $validEntry = $null; $validEntry = $entries | Where-Object { ($_.SID -eq $sid) -and ($_.Value -eq $SSAValue) }
                    if(-not $validEntry) {
                        if($domainExceptionActive) {
                            $gpresultRequested = $true
                        } else {
                            Write-Log -Text "No valid entry found for '$entryName' entry for SID '$sid'. Setting local entry to $SSAValue."
                            Set-HKURegistryEntries -SID $sid -RelativeKey $rootKeyLocal -Name $entryName -Value $SSAValue -PropertyType String | Out-Null
                        }
                    }
                }
            }
            "ScreenSaverIsSecure" {
                foreach($sid in $sids) {
                    $validEntry = $null; $validEntry = $entries | Where-Object { ($_.SID -eq $sid) -and ($_.Value -eq $SSISValue) }
                    if(-not $validEntry) {
                        if($domainExceptionActive) {
                            $gpresultRequested = $true
                        } else {
                            Write-Log -Text "No valid entry found for '$entryName' entry for SID '$sid'. Setting local entry to $SSISValue."
                            Set-HKURegistryEntries -SID $sid -RelativeKey $rootKeyLocal -Name $entryName -Value $SSISValue -PropertyType String | Out-Null
                        }
                    }
                }
            }
            "ScreenSaveTimeOut" { 
                foreach($sid in $sids) {
                    $validEntry = $null; $validEntry = $entries | Where-Object { ($_.SID -eq $sid) -and ($_.Value) -and ([Int]::Parse($_.Value) -le $SSTOValue) }
                    if(-not $validEntry) {
                        if($domainExceptionActive) {
                            $gpresultRequested = $true
                        } else {
                            Write-Log -Text "No valid entry found for '$entryName' entry for SID '$sid'. Setting local entry to $SSTOValue."
                            Set-HKURegistryEntries -SID $sid -RelativeKey $rootKeyLocal -Name $entryName -Value $SSTOValue -PropertyType String | Out-Null
                        }
                    }
                }
            }
            "SCRNSAVE.EXE" {
                foreach($sid in $sids) {
                    $validEntry = $null; $validEntry = $entries | Where-Object { ($_.SID -eq $sid) -and ($screensavers -contains $_.Value) }
                    if(-not $validEntry) {
                        if($domainExceptionActive) {
                            $gpresultRequested = $true
                        } else {
                            Write-Log -Text "No valid entry found for '$entryName' entry for SID '$sid'. Setting local entry to $SSEXEValue."
                            Set-HKURegistryEntries -SID $sid -RelativeKey $rootKeyLocal -Name $entryName -Value $SSEXEValue -PropertyType String | Out-Null
                        }
                    }
                }
            }
            Default {}
        }
    }
    if($gpresultRequested) {
        Write-Log -Text "Domain exception active. No configuration changes will be made. Running GPRESULT."
        gpresult /SCOPE COMPUTER /H $reportPathComputer /F

        # Attempt to parse username from discovered SIDS
        $sids = @($entries | Select-Object -ExpandProperty SID -Unique)
        $reportUsername = $null
        foreach($sid in $sids) {
            $sidObject = $(New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $SID)
            try { 
                $ntAccount = $sidObject.Translate([System.Security.Principal.NTAccount])
                if($ntAccount.Value -notcontains $env:COMPUTERNAME) {
                    $reportUsername = $ntAccount.Value
                    break
                }
            } catch { }
        }
        $(New-Object System.Security.Principal.SecurityIdentifier -ArgumentList $SID).Translate([System.Security.Principal.NTAccount]).Value

        # Run report if valid username found.
        if($reportUsername) {
            Write-Log -Text "Running GPRESULT for user '$reportUsername'..."
            gpresult /SCOPE USER /USER $reportUsername /H $reportPathUser /F
        } else {
            Write-Log -Text "Unable to parse domain user from results. Skipping user GPRESULT." -Type FAIL
        }
    }
}