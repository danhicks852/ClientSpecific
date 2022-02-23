<#
.SYNOPSIS
    Briefly Describe the script
.EXAMPLE
    How to run the script
    c:\> Get-ScriptTemplate.ps1 -param 123
.PARAMETER -param
    Describe each paramater your script uses
.NOTES
    Additional script notes here.
#>
#Configure Paramaters and validate input if needed.
param (
    [Parameter(Mandatory)]
    [ValidatePattern('regex')]
    [string]$param
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if(-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
} else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
### Process ###