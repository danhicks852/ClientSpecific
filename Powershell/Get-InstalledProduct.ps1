<#
.SYNOPSIS
    Checks for the following remote software installed on the endpoint:
        TeamViewer
        VnC
        UtraViewer
        ConnectWise.Automate
        ScreenConnect
        LogMeIn
        AnyDesk
        Chrome.remote.Desktop
        SplashTop
.EXAMPLE
    PS C:\> Get-InstalledProduct.ps1
.OUTPUTS
    Update-Made2Manage-log.txt
    Update-Made2Manage-data.txt
#>
### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
}

else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
$results = Get-Package | Where-Object { $_.Name -match 'Splashtop|ScreenConnect|AnyDesk|ConnectWise|UltraViewer|LogMeIn|VNC|TeamViewer' }
if ($results.Name) {
    Write-Log -Text 'Remote access clients were found on this endpoint. See the CF xPVAL Remote Tools Installed for more details.' -Type LOG
    $list = $Results.Name -join (', ')
    $list = $list -Replace ('\([^()]*\)', '')
    Write-Log -Text "$list" -Type Data
}

else {
    Write-Log -Text 'No Remote access clients were found on this endpoint.' -Type LOG
    Write-Log -Text 'None' -Type Data
}