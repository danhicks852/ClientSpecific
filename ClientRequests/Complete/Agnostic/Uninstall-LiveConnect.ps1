<#
.SYNOPSIS
    Uninstalls LiveConnect, removed directories associated with the update bug.
.EXAMPLE
./Uninstall-LiveConnect.ps1
#>

### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
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
#try finding 64 bit app
function Uninstall-LiveConnect{
$uninstallString = (Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty | Where-Object {$_.Displayname -eq "Live Connect"} | Select-Object -exp UninstallString)# -replace " *\/uninstall.*$","" -replace """",""
if($uninstallString.Length -eq 0){ #not found in 64 bit hive
    #try 32 bit instead
    $uninstallString = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" | Get-ItemProperty | Where-Object {$_.Displayname -eq "Live Connect"} | Select-Object -exp UninstallString)# -replace " *\/uninstall.*$","" -replace """",""
    if($uninstallString.Length -eq 0){ #also not found in 32 bit hive
        Write-Log -Text "Software not installed on system" -Type DATA
    }
    else { #found in 32 bit hive
        Write-Log -Text "32bit Software Version found. Uninstalling." -Type DATA
        $uninstallString = $uninstallString -replace "^msiexec\.exe \/I+","/X"
        & MsiExec.exe $uninstallString /qn
        Write-Log -Text "32-bit version uninstalled."
    }
}
else { #found in 64 bit hive
    Write-Log -Text "64 bit software version found. uninstalling." -Type DATA
    $uninstallString = $uninstallString -replace "^msiexec\.exe \/I+","/X"
    & MsiExec.exe $uninstallString /qn
    Write-Log -Text "64-bit version uninstalled."
}
}

Uninstall-LiveConnect
Get-ChildItem -Path "$env:localappdata\Kaseya" -File -Recurse | Remove-Item -Recurse -Force
Get-ChildItem -Path "C:\ProgramData\Package Cache"-File -Recurse  | Remove-Item -Recurse -Force
