<#
.SYNOPSIS
    VSA to VSA Migration Automation
.EXAMPLE
    PS C:\>Invoke-VSAAgentTransfer.ps1 -a dev-win10-1.testmachines.proval
.PARAMETER AgentID
    The agent ID, passed in from VSA
.OUTPUTS
    Invoke-VsaAgentTransfer-log.txt
    Invoke-VsaAgentTransfer-data.txt
    Invoke-VsaAgentTransfer-error.txt
.NOTES
    Machine Groups must match between both VSAs or the process will fail
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][Alias ('a')][String]$AgentId
)
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
Remove-Item -Path "$env:ProgramData\_automation\AgentProcedure\AgentMigration\Get-VSAGroup-data.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:ProgramData\_automation\AgentProcedure\AgentMigration\Get-VSAGroup-log.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:ProgramData\_automation\AgentProcedure\AgentMigration\Get-VSAGroup-error.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:ProgramData\_automation\AgentProcedure\AgentMigration\KcsSetup.exe" -ErrorAction SilentlyContinue
$AgentIdArray= $AgentId.Split('.')
$agentName, $ReverseGroupName = $AgentIdArray
$GroupName = $reverseGroupName -join '.'
Write-Log -Text "Group: $GroupName" -Type LOG
Write-Log -Text "Agent: $agentName" -Type LOG
(New-Object System.Net.WebClient).DownloadFile("https://file.provaltech.com/repo/kaseya/clients/myIT/migrationagent/KcsSetup.exe","$env:ProgramData\_automation\AgentProcedure\AgentMigration\KcsSetup.exe")
Start-Process -FilePath "$env:ProgramData\_automation\AgentProcedure\AgentMigration\KcsSetup.exe" -ArgumentList "/g=$GroupName /s /c" -Wait
Start-Sleep -Seconds 10
if((Get-Service | Where-Object {$_.DisplayName -match 'Kaseya*'}).count -gt 2){
    Write-Log -Text 'Two or more Kaseya agents found, indicating successful installation' -Type LOG
    Write-Log -Text 'Success' -Type DATA
}
else {
    Write-Log -Text 'Two or more Kaseya agents not found, indicating unsuccessful installation. Contact ProVal Support.' -Type ERROR
    Write-Log -Text 'Success' -Type DATA
}