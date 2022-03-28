<#
.SYNOPSIS
    New Laptop Setup
    Optionally Performs any or all of the following:
    -Removes Pre-installed AppXPackages that are generally unneeded
    -Installs commonly used software
    -Installs and configured Hyper-V Host for dev environment
    -Installs any binary placed in the CustomInstallers Directory, which should be located in the same directory as this script.
    -Configures Git, Posh Git, nuget
.PARAMETER -RemoveBloatware
    Removes the following pre-installed AppXPackages:
    ---Microsoft.3DBuilder
    ---skypeapp
    ---Microsoft.Getstarted
    ---Microsoft.MicrosoftSolitaireCollection
    ---Microsoft.BingFinance
    ---Microsoft.BingNews
    ---Microsoft.Office.OneNote
    ---Microsoft.BingSports
    ---Microsoft.BingTravel
    ---Microsoft.BingFoodAndDrink
    ---Microsoft.BingHealthAndFitness
    ---Microsoft.MicrosoftOfficeHub
.PARAMETER -InstallSoftware
    Installs the following software:
    ---Chrome
    ---adobereader
    ---obs-studio
    ---audacity
    ---dotpeek
    ---microsoft-windows-terminal
    ---vscode
    ---gsudo
    ---git
    ---zoom
    ---parsec
    ---treesizefree
    ---greenshot
    ---ditto
.PARAMETER -InstallCustomSoftware
    loops through any binaries in the custom directory "CustomInstallers", located in the root of the script directory, and runs them one by one. 
    The script will wait for each installation to complete before moving on to the next one. 
    This parameter requires attended setup.
.PARAMETER -EnableHyperV
    Enables HyperV on the workstation.
    Will invoke a reboot at the end of the script.
.PARAMETER -SetupGit
    Installs Nuget, configures package managers, configures powershell profile, configures git with user information
.PARAMETER -SetupPrefs
    Configures the following settings on the endpoint:
    ---Sets Timezone to EST
    ---Sets Power plan to high performance
    ---Removes Cortana, Search, news&interests from taskbar
    ---Enables small icons on taskbar
    ---Enables hidden files and file extensions in explorer
    ---Sets Dark Mode windows theme
    ---Clears desktop icons
    ---Empties recycle bin
    Will invoke a reboot at the end of the script.
.EXAMPLE
    c:\>InvokeDevEnvSetup.ps1 -RemoveBloatware -InstallCustomSoftware
    C:\>InvokeDevEnvSetup.ps1 -All

.NOTES
    Dan's Laptop setup, preferences, and more 
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][switch]$RemoveBloatware,
    [Parameter(Mandatory = $false)][switch]$InstallSoftware,
    [Parameter(Mandatory = $false)][switch]$InstallCustomSoftware,
    [Parameter(Mandatory = $false)][switch]$EnableHyperV,
    [Parameter(Mandatory = $false)][switch]$SetupGit,
    [Parameter(Mandatory = $false)][switch]$SetupPrefs,
    [Parameter(Mandatory = $false)][switch]$All
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
    Update-PowerShell
    if ($powershellUpgraded) { return }
    if ($powershellOutdated) { return }
}
else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}

function Set-ExplorerAdvancedOption {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object]$Value
    )
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name $Name -Value $Value -Type DWORD -Force
}
function Invoke-BloatwareCleanup {
    Get-AppxPackage -name "Microsoft.3DBuilder" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.MicrosoftOfficeHub" | Remove-AppxPackage
    Get-AppxPackage *skypeapp* | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.Getstarted" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingFinance" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingNews" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.Office.OneNote" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingSports" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingTravel" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingFoodAndDrink" | Remove-AppxPackage
    Get-AppxPackage -name "Microsoft.BingHealthAndFitness" | Remove-AppxPackage
}
function Install-GeneralSoftware {
    choco install `
        googlechrome `
        adobereader `
        obs-studio `
        audacity `
        dotpeek `
        microsoft-windows-terminal `
        vscode `
        gsudo `
        git `
        zoom `
        parsec `
        treesizefree `
        greenshot `
        ditto  `
}
function Install-CustomSoftware {
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_Community.exe" -OutFile ./CustomInstallers/vs.exe
    foreach ($installers in (Get-ChildItem ./CustomInstallers)) {
        Start-Process $installer.Name -Wait
    }
}
function Enable-HyperV {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    $rebootNeeded = 1
    return $rebootNeeded
}
function Invoke-GitSetup {
    refreshenv
    $env:path += 'C:\Program Files\Git\cmd'
    Install-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name "posh-git"
    $profileAppendPosh = 'Import-Module -Name "posh-git"'
    $profileAppendSudo = 'Set-Alias sudo gsudo'
    $profileAppendPosh | Out-File -Encoding Ascii -append "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $profileAppendSudo | Out-File -Encoding Ascii -append "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    Import-Module -Name "posh-git"
    refreshenv
    git config --global user.name 'Dan Hicks'
    git config --global user.email 'dan.hicks@provaltech.com'
}
function Set-UserPrefs {
    Set-TimeZone "Eastern Standard Time"
    powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds -Name ShellFeedsTaskbarViewMode -Value 2 -Type DWord -Force
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type DWORD -Force
    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power -Name HiberbootEnabled -Value 0 -Type DWORD -Force
    Set-ExplorerAdvancedOption -Name 'ShowTaskViewButton' -Value 0 
    Set-ExplorerAdvancedOption -Name 'ShowCortanaButton' -Value 0
    Set-ExplorerAdvancedOption -Name 'TaskbarSmallIcons' -Value 1
    Set-ExplorerAdvancedOption -Name 'Hidden' -Value 1
    Set-ExplorerAdvancedOption -Name 'HideFileExt' -Value 0
    Set-AllNetworksPrivate
    Remove-Item $env:USERPROFILE\Desktop\* -Force -Confirm:$false
    Clear-RecycleBin -Force -Confirm:$false
    $rebootNeeded = 1
    return $rebootNeeded
}
function Set-AllNetworksPrivate{
    $netProfiles = Get-NetConnectionProfile
    foreach ($profile in $netProfiles){
        Set-NetConnectionProfile -Name $profile.Name -networkCategory Private
    }
}
function Test-RegistryValue {
    param (
     [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path,
     [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value
    )
    try {
     Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
     return $true
    }
    catch {
     return $false
    }
   }
function Get-PendingReboots {
   [bool]$PendingReboot = $false
   #Check for Keys
   If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -eq $true)
   {
$PendingReboot = $true
   }
   If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts") -eq $true)
   {
    $PendingReboot = $true
   }
   #Check for Values
   If ((Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "RebootInProgress") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "PackagesPending") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Value "PendingFileRenameOperations") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Value "PendingFileRenameOperations2") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Value "DVDRebootSignal") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "JoinDomain") -eq $true)
   {
    $PendingReboot = $true
   }
   If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "AvoidSpnSet") -eq $true)
   {
    $PendingReboot = $true
   }
   return $PendingReboot
}
function Invoke-Cleanup{
    Write-Log -Text 'The selected Modules have been completed.'
    Get-PendingReboots
    if ($PendingReboot) { 
        Write-Log -Text 'A reboot is pending on this machine after setup. This machine will now be restarted. Press enter to continue.' -LOG
        Read-Host
        Restart-Computer 
    }
}
#logic
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
if ($All) {
    Invoke-BloatwareCleanup
    Install-GeneralSoftware
    Install-CustomSoftware
    Enable-HyperV
    Invoke-GitSetup
    Set-UserPrefs
    Invoke-Cleanup
    break
}
else{
if ($RemoveBloatware) { Invoke-BloatwareCleanup }
if ($InstallSoftware) { Install-GeneralSoftware }
if ($InstallCustomSoftware) { Install-CustomSoftware }
if ($EnableHyperV) { Enable-HyperV }
if ($SetupGit) { Invoke-GitSetup }
if ($SetupPrefs) { Set-UserPrefs }
Invoke-Cleanup
}
