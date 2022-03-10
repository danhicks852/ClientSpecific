#region Template
<#
.SYNOPSIS
    Updates UEFI HP Machine to latest firmware version
.EXAMPLE
    C:\>./Invoke-BIOSUpgradeHP.ps1
.PARAMETER -param
    Describe each paramater your script uses
.NOTES
    Additional script notes here.
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
$biosCheck = Confirm-SecureBootUEFI
if ($biosCheck -eq 'Cmdlet not supported on this platform') {
    Write-Log -Text "This script is only supported on UEFI Enabled Machines" -Type ERROR
    break
}
Install-Module -Name PowerShellGet  -Force
Install-Module -Name PowerShellGet -SkipPublisherCheck -Force
Install-Module -Name HPCMSL -AcceptLicense
$resultCapture = $(Get-HPBIOSUpdates -Latest -Flash -Yes -Quiet) 6>&1
Write-Log -Text $resultCapture -Type LOG