<#
.SYNOPSIS
    Gets group from agent ID Passed in from kaseya
.EXAMPLE
    PS C:\>Get-VSAGroup.ps1 -a dev-win10-1.testmachines.proval
    will output agent name, and Groups, in the order 'subgroup > group > org'
.PARAMETER AgentID
    The agent ID, passed in from VSA
.PARAMETER Reverse
    Reverses the group name to 'org > group > subgroup', useful in some API applications
.OUTPUTS
    Get-VSAGroup.ps1-data.txt
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][Alias ('a')][String]$AgentId,
    [Parameter(Mandatory = $false)][Alias ('r')][switch]$Reverse
)
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
Remove-Item -Path "$env:ProgramData\_automation\AgentProcedure\AgentMigration\Get-VSAGroup-data.txt" -ErrorAction SilentlyContinue
$AgentIdArray = $AgentId.Split('.')
$agentName, $splitGroupName = $AgentIdArray
if($reverse){[array]::Reverse($splitGroupName)}
$GroupName = $splitGroupName -join '.'
Write-Log -Text "Group: $GroupName" -Type DATA
Write-Log -Text "Agent: $agentName" -Type DATA