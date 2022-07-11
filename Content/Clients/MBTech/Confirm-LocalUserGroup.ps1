#region template
<#
.SYNOPSIS
    Checks for a local user and writes the result to data log
.EXAMPLE
    c:\> Confirm-LocalUserAccount.ps1 -username USER
.PARAMETER -username
    Provide the local user name to check against
.NOTES
    Written by Dan Hicks @ ProvalTech for MBTech
#>
#Configure Paramaters and validate input if needed.

### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
#endregion template
$groupMembers = Get-LocalGroupMember -Name Administrators
foreach ($member in $groupMembers) {
    if ($member.Name -like 'RANKEN\S_IT') {
        $found = 1
    }
}

if (!($found)) {
    write-log -text 'S_IT not found.' -Type DATA
} else {
    write-log -text 'S_IT exists on this endpoint.' -DATA
}