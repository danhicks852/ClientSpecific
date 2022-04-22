<#
.SYNOPSIS
    
.EXAMPLE
    
.PARAMETER -ProvidedUsername
    
.NOTES
    
#Configure Paramaters and validate input if needed.
#>
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}

$results = Get-Service | Where-Object {($_.DisplayName -eq "Sophos Health Service" -or $_.DisplayName -eq "Sophos MCS Agent" -or $_.DisplayName -eq "Sophos MCS Client")}
if(!($results)){
    Write-Log -Text "Sophos Services Not Found" -Type LOG
    Write-Log -Text 'none' -Type DATA
}
foreach ($result in $results){
    Write-Log -Text "Sophos Service $($result.DisplayName) found on the system in state $($result.Status)." -Type LOG
    Write-Log -Text $result.DisplayName -Type DATA
}