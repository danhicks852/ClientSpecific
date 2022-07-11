
### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
$oneDriveKey = Get-Item -Path Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\OneDrive -erroraction SilentlyContinue# | Select-Object -ExpandProperty Property 
if(!($oneDriveKey)){
    New-Item -Path Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows -Name OneDrive
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Value 1
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1
}
else{
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Value 1
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1
}

Start-Service 'OCS Inventory Service'
$member = (Get-WMIObject -ClassName Win32_ComputerSystem).Username; Remove-LocalGroupMember -Group Administrators -Member $member