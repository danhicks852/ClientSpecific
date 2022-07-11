<#
.SYNOPSIS
    
.EXAMPLE
    
.PARAMETER -Username
    
.NOTES
    ITG.5edf11bfc8e9fe0e87549e6b70ab559a.bAucysg1F_XsgBr-Gzku-sQV5XPJ2XZ5rA4WzOpFSWdWrTH3X7HlQRhmqd2cBiRz
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][string]$Key
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
if (-not(Get-InstalledModule ITGlueAPI -ErrorAction silentlycontinue)) {
    Install-Module -Name ITGlueAPI -Force -Confirm:$false
    Write-Log -Text "ITGlueAPI Module Installed and Loaded." -Type LOG
}
else {
    Import-Module ITGlueAPI -ErrorAction silentlycontinue
    Write-Log -Text "ITGlueAPI Module Loaded." -Type LOG
}
Add-ITGlueBaseURI -base_uri "https://api.itglue.com"
Add-ITGlueAPIKey -Api_Key $Key
Set-ITGluePasswords 
$orgs = Get-ITGlueOrganizations
$orgs.data.attributes | ? {$_.name -like '*ProVal*'} | Select -ExpandProperty organization-id