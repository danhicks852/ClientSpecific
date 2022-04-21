[CmdletBinding()]
param ([Parameter(Mandatory = $false)][string]$TimeZone = "eastern")
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
}
else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
function Set-DesktopShortcut {
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true)][string]$appName,
        [Parameter(Mandatory = $true)][string]$appSourcePath,
        [Parameter(Mandatory = $false)][switch]$setRASIcon,
        [Parameter(Mandatory = $false)][string]$publicShortcutPath = "$env:HOMEDRIVE\Users\Public\Desktop\"
    )
    if ($setRASIcon) {
        Invoke-WebRequest https://file.provaltech.com/repo/kaseya/clients/groff/icon.ico -OutFile "$env:HOMEDRIVE\rasphone.ico"
        $WScriptObj = New-Object -ComObject ("Wscript.Shell")
        $shortcut = $WScriptObj.CreateShortcut("$publicShortcutPath\$appName.lnk")
        $shortcut.TargetPath = $appSourcePath
        $shortcut.IconLocation = "$env:HOMEDRIVE\rasphone.ico"
        $shortcut.Save()
    }
    else {
        $WScriptObj = New-Object -ComObject ("Wscript.Shell")
        $shortcut = $WScriptObj.CreateShortcut("$publicShortcutPath\$appName.lnk")
        $shortcut.TargetPath = $appSourcePath
        $shortcut.Save()
    }
}
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install googlechrome 7zip firefox adobereader -y
<#  Office Installation
Write-Log -Text "Installing Office" -Type LOG
Invoke-WebRequest https://file.provaltech.com/repo/kaseya/clients/groff/office.exe -OutFile "$env:HOMEDRIVE\office.exe"
Start-Process -FilePath "$env:HOMEDRIVE\office.exe" -Wait
#>
Write-Log -Text "Removing all desktop icons." -Type LOG
Remove-Item $env:HOMEDRIVE\Users\*\Desktop\* -Force
Write-Log -Text "Adding standardized Desktop Icons to all users" -Type LOG
Set-DesktopShortcut -appName Chrome -appSourcePath "$env:ProgramFiles (x86)\Google\Chrome\Application\chrome.exe"
Set-DesktopShortcut -appName Firefox -appSourcePath "$env:PROGRAMFILES\Mozilla Firefox\firefox.exe"
Set-DesktopShortcut -appName Outlook -appSourcePath "$env:PROGRAMFILES\Microsoft Office\root\Office16\OUTLOOK.EXE"
Set-DesktopShortcut -appName Word -appSourcePath "$env:PROGRAMFILES\Microsoft Office\root\Office16\WORD.EXE"
Set-DesktopShortcut -appName Excel -appSourcePath "$env:PROGRAMFILES\Microsoft Office\root\Office16\EXCEL.EXE"
Set-DesktopShortcut -appName RasPhone -appSourcePath "$env:WinDir\system32\rasphone.exe" -setRASIcon
Write-Log -Text "Setting Timezone" -Type LOG
switch ($TimeZone) {
    eastern { Set-TimeZone "Eastern Standard Time" }
    pacific { Set-TimeZone "Pacific Standard Time" }
    central { Set-TimeZone "Central Standard Time" }
    mountain { Set-TimeZone "Mountian Standard Time" }
    Default {}
}
Write-Log -Text "Preparing to modify registry" -Type LOG
& REGEDIT /E regbackup.reg
Write-Log -Text "Registry backed up, downloading assets" -Type LOG
Invoke-WebRequest "https://file.provaltech.com/repo/script/Set-UserRegistryValue.ps1" -OutFile "$PSScriptRoot\Set-UserRegistryValue.ps1"
Write-Log -Text "Assets downloaded. Performing changes." -Type LOG
Write-Log -Text "Disabling News & Interests toolbar for user $profile" -Type LOG
& .\Set-UserRegistryValue -Path "Software\Microsoft\Windows\CurrentVersion\Feeds" -Keyname ShellFeedsTaskbarViewMode -PropertyType DWORD -Value 2 -Force   
Write-Log -Text "Disabling Taskbar Task View button for user $profile" -Type LOG
& .\Set-UserRegistryValue -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Keyname ShowTaskViewButton -PropertyType DWORD -Value 0 -Force
Write-Log -Text "Disabling Taskbar Cortana Button for user $profile" -Type LOG
& .\Set-UserRegistryValue -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Keyname ShowCortanaButton -PropertyType DWORD -Value 0 -Force
Write-Log -Text "Removing all pins from Taskbar" -Type LOG
& .\Set-UserRegistryValue -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Keyname Favorites -PropertyType Binary -Value ff -Force
Write-Log -Text "Disabling lock screen notifications" -Type LOG
Set-ItemProperty -Path HKLM:"Software\Policies\Microsoft\Windows\System" -Name 	DisableLockScreenAppNotifications -Value 1 -Type DWORD -Force
Write-Log -Text "Disabling sleep and display standby on battery" -Type LOG
Write-Log -Text "Setting Power Options on Battery" -Type LOG
& powercfg.exe -x -monitor-timeout-dc 0
& powercfg.exe -x -standby-timeout-dc 0
& powercfg.exe -x -hibernate-timeout-dc 0
Write-Log -Text "Configuration Complete" -Type LOG
& taskkill /f /im explorer.exe
& explorer.exe