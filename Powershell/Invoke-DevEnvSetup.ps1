<#
.SYNOPSIS
    New Laptop Setup
    Performs the following:
    -Removes Pre-installed AppXPackages that are generally unneeded
    -Installs commonly used software
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
    -Installs and configured Hyper-V Host for dev environment
    -Installs several pieces of software from included binary
    ---Office
    ---Tailscale
    ---OpenVPN
    ---Kaseya Agent
    ---Downloads and installs Visual Studio 2022 Community
    -Configures Git, Posh Git, nuget
    -Sets Timezone to EST
    -Sets Power plan to high performance
    -Removes Cortana, Search, news&interests from taskbar
    -Enables small icons on taskbar
    -Enables hidden files and file extensions in explorer
    -Sets Dark Mode windows theme
    -Clears desktop icons
    -Empties recycle bin
.EXAMPLE
    c:\>InvokeDevEnvSetup
.NOTES
    Dan's Laptop setup, preferences, and more
    
#>
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
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#bloatware cleanup
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
#general software installations.
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
Start-Process './OfficeSetup.exe' -Wait
Start-Process './openvpn-Prod2-PFSense-UDP4-1194-dan.hicks-install-2.5.2-I601-amd64.exe' -Wait
Start-Process './KcsSetup.exe' -Wait
Start-Process './tailscale-ipn-setup-1.22.2.exe' -wait
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_Community.exe" -OutFile ./vs.exe
Start-Process './vs.exe' -wait
#Install Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
#git setup
refreshenv
$env:path+='C:\Program Files\Git\cmd'
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
#Set Time to EST
Set-TimeZone "Eastern Standard Time"
#set High Performance Power Plan
powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
<#
Sets the following:
-Remove Cortana, Task View, Search bar, and News&Interests from the taskbar
-Sets small icons in taskbar
-Show known file extensions
-Show hidden files & folders
-Set Dark Mode in Windows 10
-Disable Fast Boot
#>
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds -Name ShellFeedsTaskbarViewMode -Value 2 -Type DWord -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type DWORD -Force
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power -Name HiberbootEnabled -Value 0 -Type DWORD -Force
Set-ExplorerAdvancedOption -Name 'ShowTaskViewButton' -Value 0 
Set-ExplorerAdvancedOption -Name 'ShowCortanaButton' -Value 0
Set-ExplorerAdvancedOption -Name 'TaskbarSmallIcons' -Value 1
Set-ExplorerAdvancedOption -Name 'Hidden' -Value 1
Set-ExplorerAdvancedOption -Name 'HideFileExt' -Value 0
#remove icons from desktop
Remove-Item $env:USERPROFILE\Desktop\* -Force -Confirm:$false
#empty Recycle Bin
Clear-RecycleBin -Force -Confirm:$false
Restart-Computer
