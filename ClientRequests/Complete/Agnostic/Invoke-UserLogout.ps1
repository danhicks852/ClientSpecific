<#
.SYNOPSIS
    Logs a specified user(s) out of the system
.EXAMPLE
    c:\> Invoke-UserLogout.ps1 -userlist "john.doe","jane.doe"
.PARAMETER User
    Provide username to logoff
.PARAMETER Regex
    Provide a regex string to match multiple users for log off. For example, passing "^yourdomainhere\\" would log off all users on the yourdomainhere domain.
.NOTES
    Written by dan.hicks@provaltech.com and rewritten by Stephen Nix. Created for agnostic use at request of MB Technologies Group.
#>
#Configure Paramaters and validate input if needed.
param (
    [Parameter(Mandatory=$true, ParameterSetName="Regex")][string]$Regex,
    [Parameter(Mandatory=$true, ParameterSetName="List")][string]$User
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if(-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
} else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
### Process ###
#Gather full list of online sessions.
$logoffCommand = "$env:windir\System32\logoff.exe"
$userSessions = $null
if($Regex) {
    Write-Log -Text "Checking if sessions exist with a pattern matching regex string: '$Regex'." -Type LOG
    $userSessions = @(Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -match $Regex } | Sort-Object SessionId -Unique)
} elseif ($User -match "\\") {
    Write-Log -Text "Checking if $User is logged in." -Type LOG
    $userSessions = @(Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -eq $User } | Sort-Object SessionId -Unique)
} else {
    Write-Log -Text "Checking if $User is logged in." -Type LOG
    $userSessions = @(Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object { ($_.UserName -replace '.*\\','') -eq $User } | Sort-Object SessionId -Unique)
}
foreach($session in $userSessions) {
    Write-Log -Text "$($currentuser.Username):$($currentuser.SessionID) is currently logged in. Initiating Log Off" -Type LOG
    & $logOffCommand $currentuser.SessionID
    Write-Log -Text "$($currentuser.Username):$($currentuser.SessionID) logged out." -Type DATA
}