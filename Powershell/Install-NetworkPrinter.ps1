<#
.SYNOPSIS
    Installs the ImageRUNNER ADVANCE C5550I III printer at IP address 10.10.100.1
.EXAMPLE
    c:\>Install-NetworkPrinter.ps1
.NOTES
    Hardcoded for specific environment and printer For Altourage.
    
#>
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
    Update-PowerShell
    if ($powershellUpgraded) { return }
    if ($powershellOutdated) { return }
}
else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
$portExist = Get-Printerport -Name "IP_10.10.100.1" -ErrorAction SilentlyContinue
if (-not $portExist) { Add-PrinterPort -Name "IP_10.10.100.1" -PrinterHostAddress "10.10.100.1" }
& pnputil.exe "c:\kworking\System\ufrii\Driver\CNLB0MA64.INF"
Add-PrinterDriver -Name "Canon Generic Plus UFR II"
Add-Printer -DriverName "Canon Generic Plus UFR II" -Name "imageRUNNER ADVANCE C5550i III" -PortName "IP_10.10.100.1"
