<#
.SYNOPSIS
Uninstalls, then hides, a specified list of KB articles
.EXAMPLE
C:> ./Invoke-UninstallHideUpdate -KBArticles "KB100000","KB200000"
.PARAMETER KBArticles
Accepts a string array seperated by commas
.NOTES
This powershell script will require machines to be manually rebooted if reboot is required.
#>
#changelog 1/27/22 added windows update pause to the procedure.
#changelog 1/28/22 switched to stopping services, which also seems to work. Kept pause code for reference or reversion if necesarry.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string[]]$KBArticles
)
### Bootstrap ###
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
### Process ###
<#function set-updatepause{ 
$pause = $pause.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )
$pause_start = (Get-Date)
$pause_start = $pause_start.ToUniversalTime().ToString( "yyyy-MM-ddTHH:mm:ssZ" )
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseUpdatesExpiryTime' -Value $pause                                                                                        
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseFeatureUpdatesStartTime' -Value $pause_start
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseFeatureUpdatesEndTime' -Value $pause
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseQualityUpdatesStartTime' -Value $pause_start
Set-itemproperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseQualityUpdatesEndTime' -Value $pause
Set-itemproperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseUpdatesStartTime' -Value $pause_start
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force
New-ItemProperty -Path  'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -PropertyType DWORD -Value 1
}#>

function Set-UpdateServiceStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateScript("^(start|stop)")][string[]]$ServiceAction
    )
    switch ($ServiceAction) {
        "start" { 
            Start-Service -Name "wuauserv" 
            Start-Service -Name "BITS"
            Start-Service -Name "CryptSvc"
            Write-Log -Text "Windows update services started" -Type LOG
        }
        "stop" {
            Stop-Service -Name "wuauserv" -Force
            Stop-Service -Name "BITS" -Force
            Stop-Service -Name "CryptSvc" -Force
            Write-Log -Text "Windows update services stopped" -Type LOG
        }
    }
}
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction SilentlyContinue
if (-not(Get-InstalledModule PSWindowsUpdate -ErrorAction silentlycontinue)) {
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    Write-Log -Text "PSWindowsUpdate Module Installed and Loaded." -Type LOG
}
else {
    Import-Module PSWindowsUpdate -ErrorAction silentlycontinue
    Write-Log -Text "PSWindowsUpdate Module Loaded." -Type LOG
}
#Set-updatepause
Set-UpdateServiceStatus -ServiceAction stop
foreach ($KBArticle in $KBArticles) {
    Remove-WindowsUpdate -KBArticleID $KBArticle
    Write-Log -Text $KBArticle" Uninstalled." -Type LOG
    Get-WindowsUpdate -KBArticleID $KBArticle -Hide -Confirm:$False
    Write-Log -Text $KBArticle" Hidden from Windows Update." -Type LOG
}
Set-UpdateServiceStatus -ServiceAction start