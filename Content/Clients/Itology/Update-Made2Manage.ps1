<#
.SYNOPSIS
    Updates Made2Manage Client to version 7.51.951
.EXAMPLE
    PS C:\> Update-Made2Manage.ps1
    Will check for a currently installed version. If exists and out of date, the script will remove and install the latest version.
    This script will also install the latest version on machines that do not currently have it installedif -NewInstall is provided as a parameter.
.PARAMETER NewInstall
    Will install the client on endpoints that do not currently have the client installed.
.OUTPUTS
    Update-Made2Manage-log.txt
    Update-Made2Manage-data.txt
    Update-Made2Manage-error.txt
.NOTES
    Co-Authored - Stephen Nix
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][Alias ('n')][Switch]$NewInstall
)
### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
function install-newm2m{
    Remove-Item -Path "$env:windir\m2mwin.ini" -ErrorAction SilentlyContinue
    (New-Object System.Net.WebClient).DownloadFile("https://file.provaltech.com/repo/kaseya/clients/itology/m2m_751.zip","$env:ProgramData\_automation\AgentProcedure\m2m\m2m_751.zip")
    Expand-Archive -Path "$env:ProgramData\_automation\AgentProcedure\m2m\m2m_751.zip" -DestinationPath "$env:ProgramData\_automation\AgentProcedure\m2m\"
    Copy-Item -Path "$env:ProgramData\_automation\AgentProcedure\m2m\M2MWin.ini" -Destination $env:Windir
    Start-Process msiexec.exe -Wait -ArgumentList "/I `"$env:ProgramData\_automation\AgentProcedure\m2m\M2M 7.51 SP13\M2MV7.51.0921\Made2Manage ERP\M2M Client Setup\Made2Manage Client.msi`" /quiet"
    $newVer = Get-Package | Where-Object {$_.Name -match 'Made2Manage'} | Select-Object -ExpandProperty Version
    if($newVer -match '7.51.921'){
        Write-Log -Text 'Made2Manage is currently at version 7.51.' -Type Log
        Write-Log -Text "$newVer" -Type DATA
    }
    else{
        Write-Log -Text 'Software not updated. Contact ProVal Support for assistance' -Type LOG
        Write-Log -Text "$currentVer" -Type DATA
    }
}
Get-ChildItem -Path "$env:ProgramData\_automation\AgentProcedure\m2m" -Include *.* -File -Recurse | ForEach-Object { $_.Delete()}
Write-Log -Text 'Environment prep completed. Checking if update is needed on endpoint.' -Type LOG
#There is a PS bug at the moment that can't properly handle null objects in a switch case, so Stephen though of using Tee-Object to get around.
Tee-Object -InputObject (Get-Package | Where-Object {$_.Name -match 'Made2Manage'} | Select-Object -ExpandProperty Version) -Variable currentVer | Out-Null
switch ($currentVer) {
    $null {
        Write-Log -Text 'Made2Manage is not installed.' -Type LOG
        if($NewInstall){
            Write-Log -Text 'NewInstall Parameter provided at runtime. Installing M2M.' -Type LOG
            install-newm2m
        }
        else{
            Write-Log -Text 'NewInstall Parameter not provided at runtime. M2M will not be installed.' -Type Error
            Write-Log -Text "Not Installed" -Type DATA
        }
        break
      }
    {$_ -lt 7.51} {
        Write-Log -Text 'Made2Manage is out of date. Proceeding with removal and installation' -Type LOG
        & wmic product where "name like 'Made2Manage Client 750.833%%'" call uninstall
        install-newm2m
        break
    }
    Default {
        Write-Log -Text 'Made2Manage is currently at or above version 7.51. No update necesarry.' -Type ERROR
        Write-Log -Text "$currentVer" -Type DATA
        break
    }
}