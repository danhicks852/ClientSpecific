<#
.SYNOPSIS
    
.EXAMPLE
    
.PARAMETER -DNSEntries
    
.NOTES
    
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string[]]$DNSEntries
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

$adapters = Get-NetAdapter | Where-Object {-not $_.Virtual -and $_.Status -eq 'up'}
foreach ($adapter in $adapters){ 
    Set-DNSClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ($DNSEntries)
    Disable-NetAdapterBinding -Name $adapter.Name -componentID ms_tcpip6 
}