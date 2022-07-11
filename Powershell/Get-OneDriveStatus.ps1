<#
.SYNOPSIS
    Gets OneDrive Process status and starts the process if needed. Then checks if the process started successfully
.EXAMPLE

.NOTES
    
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
#script here

if(!(Get-WmiObject -Class Win32_Process -Filter "name='onedrive.exe'" | Where-Object {$_.Getowner().User -eq $env:USERNAME})) {
    Start-Process -FilePath "$($env:HOMEDRIVE)\Program Files\Microsoft OneDrive\OneDrive.exe" -ErrorAction SilentlyContinue
    Start-Process -FilePath "$($env:HOMEDRIVE)\Program Files (x86)\Microsoft OneDrive\OneDrive.exe" -ErrorAction SilentlyContinue
    Start-Process -FilePath "$($env:USERPROFILE)\AppData\Local\Microsoft\OneDrive\OneDrive.exe" -ErrorAction SilentlyContinue
    $checkProc = Get-Process | Where-Object {$_.Name -like '*onedrive*'}
    if(!($checkProc)){
        Write-Log -Text 'The Onedrive Process did not start. Please troubleshoot the endpoint.' -Type DATA
    }
    else{
        Write-Log -Text 'The Onedrive Process Started Successfully' -Type DATA
    }
}
else{ 
    Write-Log -Text 'The Onedrive Process is already started.' -Type DATA
}
