
<#
.SYNOPSIS
    Gets Azure connect version if installed
.EXAMPLE
    ./Get-AzureADConnectVersion
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
$adconnectVersion = Get-CimInstance -ClassName Win32_Product | Where-Object name -eq 'Microsoft Azure AD Connect' | Select-Object name,version
if(!($adconnectVersion)){
    Write-Log -Text 'Not Installed' -Type DATA
}
else {
    Write-Log -Text $adconnectVersion.Version -Type DATA
}