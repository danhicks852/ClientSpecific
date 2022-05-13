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
Get-appxprovisionedpackage -online | where-object {$_.displayname -like '*xbox*'} | Remove-AppXProvisionedPackage -online
Get-AppxPackage -allusers -name '*xbox*' | Remove-AppxPackage
