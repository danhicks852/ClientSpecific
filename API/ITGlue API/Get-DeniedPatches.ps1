<#
.SYNOPSIS
    Pulls Denied patches from ITGlue Flexible Assets and saves them to a log file.
.EXAMPLE
    c:\Get-DeniedPatches.ps1 -apikey ITG.XXXXXXXXXXXXXXXXXXXXxx
.PARAMETER -APIKey
    Input your ITGlue API Key to authenticate the API request. Must begin with 'ITG.'
.NOTES
    Contact ITGlue Administrator for API Key if needed.
    KB Results are output to Get-DeniedPatches-DATA.txt in CSV format.
#>
### Bootstrap ###
param (
    [Parameter(Mandatory)]
    [ValidatePattern('(^ITG\.)')]
    [string]$APIKey
)
if(-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
    Update-PowerShell
    if($powershellUpgraded) { return }
    if($powershellOutdated) { return }
} else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
### Process ###
if (-not(Get-InstalledModule ITGlueAPI -ErrorAction silentlycontinue)) {
    Install-Module -Name ITGlueAPI -Force -Confirm:$false
    Write-Log -Text "ITGlueAPI Module Installed and Loaded." -Type LOG
} else {
    Import-Module ITGlueAPI -ErrorAction silentlycontinue
    Write-Log -Text "ITGlueAPI Module Loaded." -Type LOG
}
Add-ITGlueBaseURI -base_uri "https://api.itglue.com"
Add-ITGlueAPIKey -Api_Key $APIKey
$FlexAssetResponse = Get-ITGlueFlexibleAssets -filter_flexible_asset_type_id 236189
$KBCSVResults = $FlexAssetResponse.data.attributes.traits.kb -replace "\.0","" -join ","
Write-Log -Text $KBCSVResults -Type DATA