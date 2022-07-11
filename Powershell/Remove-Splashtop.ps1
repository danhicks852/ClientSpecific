<#
.SYNOPSIS
    Uninstalls Splashtop and de-registers services
.EXAMPLE
    PS C:\> .\Remove-Splashtop.ps1
.OUTPUTS
    Output (if any)
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
$splashtop = get-WMIObject -class Win32_Product -filter "Name = 'Splashtop Streamer'"
if($splashtop){
    $splashtop.Uninstall()
    (get-WMIObject -class Win32_Product -filter "Name = 'Splashtop Software Updater'").Uninstall()
}
$splashtop = get-WMIObject -class Win32_Product -filter "Name = 'Splashtop Streamer'"
if(!($splashtop)){
    Write-Log -Text "Uninstall Complete" -Type LOG
}
else{
    Write-Log -Text "Uninstall Failed" -Type LOG
}