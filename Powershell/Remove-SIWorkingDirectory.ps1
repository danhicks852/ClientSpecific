<#
.SYNOPSIS
    Removes log files in use by kaseya so that the working directory can be deleted.
.EXAMPLE
    ./Remove-SIWorking.PS1
#Configure Paramaters and validate input if needed.
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
Write-Log -Text 'Performing a first pass deletion on the object'
Remove-Item -Path C:\SIworking -Recurse -Force -ErrorAction SilentlyContinue
Write-Log -Text 'Checking for any files that were unable to be deleted, indicating that Kaseya has locked them'
$leftovers = Get-ChildItem C:\SIworking -Recurse | Get-Member | Where-Object {$_.TypeName -eq 'System.IO.FileInfo' -and $_.Definition -match "^string PSChildName=KLOG"}
if($leftovers){Write-Log -Text "Removing Leftover Files: $leftovers" -Type DATA}
$filename = $leftovers.definition -replace "string PSChildName=",""
$interimFileName = $filename -replace "KLOG","KCTR"
$collectorName = $interimFileName -replace ".csv",""
Write-Log -Text 'Stopping collectors to unlock the file' -Type LOG
logman stop $collectorName
logman delete $collectorName
Write-Log -Text 'Performing the final Directory removal'
Remove-Item -Path C:\SIworking -Recurse -Force