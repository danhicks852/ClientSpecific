
<#
.SYNOPSIS
    List and optionally remove, all Members of the Local Group: Administrators
.EXAMPLE
    ./Get-LocalGroupMembers.ps1 -remove
.PARAMETER -remove
    USE WITH CAUTION, will remove ALL administrators from the group
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][switch]$remove
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
#using this method to pull admins instead of Get-LocalGroupMembers due to a current bug that causes the cmdlet to fail if orphaned SIDs exist.
Import-Module Microsoft.Powershell.LocalAccounts
$admins = ([ADSI]"WinNT://./Administrators").psbase.Invoke('Members') | ForEach-Object {([ADSI]$_).InvokeGet('AdsPath')}
foreach ($admin in $admins | Where-Object{$_ -notlike '*administrator*'}){
    #get only the usernames in the list
    $admin = $admin.Replace('WinNT://','')
    $admin = $admin -replace "^.*?\/"
    Write-Log -Text $admin -Type Data
    if($remove){
        Remove-LocalGroupMember -Group 'Administrators' -Member $admin
        Write-Log -Text "$admin removed from the Local Administrator Group" -Type LOG
    }
}

