<#
.SYNOPSIS
    Sets Windows 10 to a specific Feature Upgrade.
    When set to 21h2, this will prevent Windows 11 Toast Notifications that prompt for upgrade.
    Passing -Undo removes these keys from the registry, allowing for upgrade.
    Requires Windows 10 2004 and above. This is checked by the script.
.EXAMPLE
    c:\> TargetUpgradeversion.ps1 -Version 2004
        Locks Windows 10 to version 2004
    c:\> TargetUpgradeversion.ps1 -Version 21h2
        Locks Windows 10 to version 21h2 and prevents Windows 11 Upgrade Prompts.
    c:\> TargetUpgradeversion.ps1 -Undo
        Removes any existing feature upgrade lock
.PARAMETER -Version
    Accepts 2004,20h2,21h1,21h2 as valid input, locks Windows 10 to the specified Build.
.PARAMETER -Undo
    Removes any existing feature upgrade lock
.NOTES
    Written by Dan Hicks and Ram Kishore of Proval Technologies for MB Technologies 
#>
[CmdletBinding()]
param ( 
    [Parameter(Mandatory = $false)][ValidatePattern('2004|20h2|21h1|21h2')][string]$Version,
    [Parameter(Mandatory = $false)][switch]$Undo
)
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
#endregion
### Process ###
#Check if build is >2004 
if (!([System.Environment]::OSVersion.Version.Build -In 19041..19044)) {
    Write-Log -Text "This script is only compatible with Windows 10 versions at or above 2004. Aborting." -Type ERROR
    break
}
else { Write-Log -Text "Windows 10 Build is supported." }
#set vars
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$regNames = [PSCustomObject]@{
    Name  = "TargetReleaseVersion"
    Type  = "DWORD"
    Value = 1
}
$regNames | Add-Member -MemberType NoteProperty -Name "TargetReleaseVersionInfo" -Type "MultiString" -Value $Version
function Test-RegExists($Path, $Name) {
    $test = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    return $test
}
if ($Undo) {
    Write-Log -Text "Removal specified at run time. Removing Target Release Version Settings." -Type LOG
    foreach ($name in $regNames) {
        Test-RegExists -Path $regPath -Name $name
        if (!($test)) {
            Write-Log -Text "$name key does not exist, aborting." -Type ERROR
            break
        }
        else {
            Remove-ItemProperty -Path $regpath -Name $name
        }
        break
    }
}
foreach ($name in $regNames) {
    Test-RegExists -Path $regPath -Name $name
    if (!($test)) {     
        New-ItemProperty -Path $regpath -Name $name.Name -Value $name.Value -Type name.Type
    }
}
else {
    Write-Log -Text "The key already exists in the registry. Overwriting" -Type LOG
    Set-ItemProperty -Path $regpath -Name $name.Name -Value $name.Value -Type name.Type
}
