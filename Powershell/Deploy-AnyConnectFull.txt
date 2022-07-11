<#
.SYNOPSIS
    Deploys Cisco any connect and all modules to the endpoint
.EXAMPLE
    c:\> Deploy-AnyConnectFull.ps1 -OrgName org
.PARAMETER -param
    enter the orgname for which you would like to deploy. New orgs need to be configured in advance.
        The orgInfo.json file needs to be places in the clients/altourage/cisco/json/orgname directory. 
        The orgname directory must match the value provided to the paramater.
.NOTES
    Installs the core module first, then iterates through all modules
        The core module is also listed in all modules but will still return an exitcode 0 since it's already installed at that point.
    the script checks the exit code from msiexec and if nonzero spits it to the error log. 
        If an error occurs during core installation, the script aborts
    If the module filenames are changed in the repo, the must be manually changed here. (ie a version number change)
    Written by Dan Hicks @ ProVal Technologies for Altourage.
#>
#Configure Paramaters and validate input if needed.
param ([Parameter(Mandatory = $true)][string]$OrgName)
#$OrgName = "fwrv"
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://file.provaltech.com/repo/script/Bootstrap.ps1")
    Set-Environment
}
else {
    Write-Log -Text "Bootstrap already loaded." -Type INIT
}
### Process ###

#set vars
$repoURL = "https://file.provaltech.com/repo/kaseya/clients/altourage/cisco"
$jsonURL = "$repoURL/json/$OrgName/OrgInfo.json"
$jsonDir = "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Umbrella"
$appDir = "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\"
#$moduleVerifyFailed = 0
$files = @(
    "anyconnect-win-4.10.04071-core-vpn-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-amp-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-dart-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-gina-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-iseposture-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-nam-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-nvm-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-posture-predeploy-k9.msi",
    "anyconnect-win-4.10.04071-umbrella-predeploy-k9.msi"
)
#download files
foreach ($file in $files) {
    Write-Log -Text "Downloading $file" -Type LOG
    Remove-Item "$workingPath\$file" -ErrorAction SilentlyContinue
    (New-Object System.Net.WebClient).DownloadFile("$repoURL/$file", "$workingPath\$file")
    if (!(Test-Path -Path "$workingPath\$file" -Pathtype Leaf)) {
        Write-Log -Text "File was not successfully downloaded. Terminating." -Type ERROR
        exit
    }
    else {
        Write-Log -Text "$file downloaded succesfully." -Type LOG
    }
}

#write JSON based on org
New-Item -Path $appDir -Name "Umbrella" -ItemType Directory -ErrorAction SilentlyContinue
Write-Log -Text "Downloading JSON file: $jsonURL to $jsonDir\OrgInfo.json" -Type LOG
Remove-Item "$jsonDir\OrgInfo.json" -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadFile($jsonURL, "$jsonDir\OrgInfo.json")

#Deploy Core
<#$installCore = #>Start-Process msiexec.exe -Wait -ArgumentList "/package $workingPath\anyconnect-win-4.10.04071-core-vpn-predeploy-k9.msi /norestart /quiet"
#$exitCode = $installCore.ExitCode
<# if(!($exitCode -gt 1)){
    Write-Log -Text "Core Module Failed to install with exit code $exitCode! Exiting procedure."
    exit
} #>

#Deploy Modules
foreach ($file in $files) {
    Write-Log -Text "Installing $file" -Type LOG
    <#$install = #>Start-Process msiexec.exe -Wait -ArgumentList "/package $workingPath\$file /norestart /quiet"
    <#     $exit = $install.ExitCode
    if(!($exit -gt 1)){
        Write-Log -Text "$file failed to install with exit code $exit." -Type ERROR
        $moduleVerifyFailed = $moduleVerifyFailed + 1
        return $moduleVerifyFailed
    }else{
        Write-Log -Text "$file Installed Successfully, or was already installed." -Type LOG
    } #>
}
<# if (!($moduleVerifyFailed -eq 0)){
    Write-Log -Text "$moduleverifyFailed modules failed to install. Please check the error log for further details." -Type ERROR
}
else{
    Write-Log -Text "All Modules installed. Process complete." -Type LOG
} #>