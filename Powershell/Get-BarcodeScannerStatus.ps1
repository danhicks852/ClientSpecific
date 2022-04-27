<#
.SYNOPSIS
    
.EXAMPLE
    
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
$barcodeDevices = Get-PNPDevice | Where-Object {$_.FriendlyName -match 'barcode'}
if (!($barcodeDevices)){
    Write-Log -Text "None exist" -Type LOG
}
else{
foreach($device in $barcodeDevices){
    if ($device.Status -eq'Unknown'){
        Write-Log -Text "$($device.FriendlyName) is Disconnected" -Type Data
    }
    else{
        Write-Log -Text "$($device.FriendlyName) is $($device.Status)" -Type Data
    }
}
}
