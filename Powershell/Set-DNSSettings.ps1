
<#
.SYNOPSIS
    
.EXAMPLE
    
.PARAMETER -ProvidedUsername
    
.NOTES
    
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$ProvidedUsername
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
Add-WindowsCapability -Online -Name Rsat.Dns.Tools
Set-DnsServerForwarder -IPAddress 208.67.222.222
Add-DNSServerForwarder -IPAddress 208.67.220.220
Set-DnsServerDiagnostics -All $True