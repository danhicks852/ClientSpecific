#region Template
<#
.SYNOPSIS
    Updates UEFI HP Machine to latest firmware version
.EXAMPLE
    C:\>./Invoke-BIOSUpgradeHP.ps1
.NOTES
    Written by Dan Hicks of ProVal Technologies for Sysintegrators
#>
#Configure Paramaters and validate input if needed.
#no params needed
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
}
else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
### Process ###
#endregion template
Write-Log -Text "Checking OS for compatiblity" -Type LOG
$biosCheck = Confirm-SecureBootUEFI
if (!($biosCheck)) {
    Write-Log -Text $biosCheck -Type ERROR
    Write-Log -Text "This script is only supported on UEFI Enabled Machines" -Type ERROR
    break
}
Write-Log -Text "System is supported." -Type LOG
Write-Log -Text "Installing PowerShellGet" -Type LOG
Install-Module -Name PowerShellGet -Force -ErrorAction SilentlyContinue
Write-Log -Text "Importing PowerShellGet" -Type LOG
Install-Module -Name PowerShellGet -SkipPublisherCheck -Force -ErrorAction SilentlyContinue
Write-Log -Text "Installing HP Tools" -Type LOG
Install-Module -Name HPCMSL -Force -AcceptLicense
Write-Log -Text "Modules installed, beginning update"
try {
    $output = (Get-HPBIOSUpdates -Flash -Yes) 2>&1
    Write-Log -Text "$output"
}
catch {
    Write-Log -Text "An error occurred during BIOS Update: $output" -Type ERROR
}
Write-Log -Text "Complete." -TYPE LOG
#$testResult = Get-HPBIOSVersion
#Write-Log -Text $testResult -Type DATA