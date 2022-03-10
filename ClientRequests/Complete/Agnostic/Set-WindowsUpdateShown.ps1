<#
.SYNOPSIS
    Manually hides provided KB articles from Windows Update using the PSWindowsUpdate nuget module
.EXAMPLE
Takes an array of KBArticles and Hides them using Get-WindowsUpdate -Hide.
    PS C:\> Set-WindowsUpdateHidden -KBArticles "KB12345667","KB123456334"
.PARAMETER KBArticles
    Array of KB IDs to hide from windows update. Passed as individual comma seperated strings enclosed in quotes. See example above.
.NOTES
    This script uses external NuGet Module PSWindowsUpdates. 
#>
param (
    [Parameter(Mandatory)][string[]]$KBArticles
)
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
if (-not(Get-InstalledModule PSWindowsUpdate -ErrorAction silentlycontinue)) {
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
}
else {
    Import-Module PSWindowsUpdate -ErrorAction silentlycontinue
}
foreach ($KBArticle in $KBArticles) {
    #TODO Validate Params
    if (-not($i.StartsWith("KB"))) {
        Write-Host "$i not a valid KB Article"
        continue  
    }
    Get-WindowsUpdate -KBArticleID $KBArticle -Show -Confirm:$False
}