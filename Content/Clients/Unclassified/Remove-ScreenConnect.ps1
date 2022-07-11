<#
.SYNOPSIS
    Uninstalls ScreenConnect clients
.EXAMPLE
#>
### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
& wmic product where "Name like 'ScreenConnect%'" call uninstall /nointeractive
$installedClients = Get-CIMInstance -classname win32_product | Where-Object {$_.Name -match "^ScreenConnect*"}
if(!($installedClients)){
    Write-Log -Text "All ScreenConnect Clients uninstalled successfully" -Type LOG
}
else{
    Write-Log -Text "Clients remain, uninstallation failed." -Type LOG
}