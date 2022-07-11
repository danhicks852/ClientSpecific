<#
.SYNOPSIS
    Creates a scheduled task to check if onedrive is running and start it if not.
.EXAMPLE
    Set-OneDriveScheduledTask.ps1
.NOTES
    Requires Get-OneDriveStatus.ps1 and downloads this script from the repo to the client machine.
#>
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
#Get Check script
Invoke-WebRequest -Uri 'https://file.provaltech.com/repo/kaseya/clients/ciracom/Get-OneDriveStatus.ps1' `
    -Outfile "$($env:ProgramData)\_automation\AgentProcedure\GetOneDriveStatus\Get-OneDriveStatus.ps1"
#setup scheduled task params
$trigger = New-ScheduledTaskTrigger -At (get-date) -RepetitionInterval (New-TimeSpan -Minutes 30) -Once
$action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-WindowStyle Hidden -File ""$($env:ProgramData)\_automation\AgentProcedure\GetOneDriveStatus\Get-OneDriveStatus.ps1"
$group = Get-LocalGroup -Name Users -ErrorAction SilentlyContinue
$principal = New-ScheduledTaskPrincipal -GroupId $group.SID.Value
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
#register the task
Unregister-ScheduledTask -TaskName 'OneDrive Checkup' -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName 'OneDrive Checkup' -InputObject $task
Start-ScheduledTask -TaskName 'OneDrive Checkup'
#give some time for the task to complete before ending the script.
Start-Sleep -Seconds 10