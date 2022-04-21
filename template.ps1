<#
.SYNOPSIS
    
.EXAMPLE

.PARAMETER ExampleParameter
    
.OUTPUTS
    
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][ValidatePattern('')][string]$ExampleParameter
)
### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
    Update-PowerShell
    if ($powershellUpgraded) { return }
    if ($powershellOutdated) { return }
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
