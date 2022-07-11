<#
.SYNOPSIS
    Short description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER Param1
    Explanation of what the parameter is for
.PARAMETER Param2
    Explanation of what the parameter is for
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
[CmdletBinding()]
param ()

### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###

# Write your code here
