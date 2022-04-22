<#
.SYNOPSIS
    Ensures 10% Maxspace Shadow Copy on the drive needed to configure Sentinel One Rollback exists.
    Will ensure sufficient drive space exists before the operation
    Will resize or add new shadow copy as needed.
.EXAMPLE
    .\InvokeSentinelOneRollbackConfiguration.ps1 -Drive F -SentinelOnePassPhrase aocij938fpoiajdpfpotato
.PARAMETER Drive
    Optional, provide a specified drive letter to configure shadowstorage on. Will default to C:\
.PARAMETER SentinelOnePassPhrase
    Required if not skipping Sentinel One Setup altogether, Actions > Agent Actions > Show passphrase. This is saved in VSA as a CF and can be passed as such.
.PARAMETER SkipSentinelOneSetup
    Optional Switch, will skip all S1 configuration and only configure VSS.
.NOTES
    Co-Authored by Stephen Nix & Dan Hicks
#Configure Paramaters and validate input if needed.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][ValidatePattern("[a-z]")][Alias ('d')][string]$Drive = 'c',
    [Parameter(Mandatory = $false)][String]$SentinelOnePassPhrase,
    [Parameter(Mandatory = $false)][Switch]$SkipSentinelOneSetup
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
##process
function Invoke-SentinelOneConfiguration {
    if(!($SkipSentinelOneSetup)){
        if(!($SentinelOnePassPhrase)){
            Write-Log -Text "Passphrase not provided. This can be located at Actions > Agent Actions > Show passphrase. Unable to configure S1" -TYPE ERROR
            throw "noPassPhrase"
        }
        $path = Get-ChildItem -Path 'C:\Program Files\SentinelOne\' | Where-Object {$_.Name -match '^sentinel agent'}
        $exePath = "C:\Program Files\SentinelOne\$($path.Name)\sentinelctl.exe"
        & $exePath  unprotect -k $SentinelOnePassPhrase
        & $exePath configure -p agent.snapshotIntervalMinutes -v 240
        & $exePath unload -a
        & $exePath load -a
        & $exePath protect
    }
    else{
        Write-Log -Text "Sentinel One Configuration skipped. Process complete." -Type LOG
    }
}
#is VSS set to manual? If not, set to manual
$vssServiceStatus = Get-Service -Name VSS | Select-Object -ExpandProperty starttype
if (!($vssServiceStatus -eq 'Manual')){
    Set-Service -Name VSS -StartupType Manual
}
$volumes = Get-Volume | Where-Object {$_.DriveLetter -eq $Drive}
foreach($volume in $volumes) {
    #running VSSAdmin Add or Resize automatically enables shadow copies, 
    #so explicit logic to ensure it's enabled is not needed.
    $shadowstorage = Get-CimInstance -ClassName Win32_ShadowStorage | Where-Object {$_.Volume.DeviceID -eq $volume.UniqueID}
    if($shadowstorage) {
        if([System.Math]::Round($shadowstorage.MaxSpace / $volume.Size, 2) -lt .1) {
            # Shadow storage needs resize
            if([System.Math]::Round(($volume.SizeRemaining + $shadowstorage.AllocatedSpace) / $volume.Size, 2) -lt .2) {
                #not enough disk space
                Write-Log 'Not enough Disk Space available to perform this action. Free up at least 20% disk space to continue.'
                throw 'Insufficient Disk Space on Target Drive'
            } else {
                & vssadmin Resize ShadowStorage /For=$($volume.DriveLetter): /On=$($volume.DriveLetter): /MaxSize=10%
                Invoke-SentinelOneConfiguration 
            }
        } else {
            Write-Log -Text 'Shadow Storage already configured correctly for 10% Max Space' -Type LOG
            Invoke-SentinelOneConfiguration 
        }
    } else {
        & "vssadmin add ShadowStorage /For=$($matchingVolume.DriveLetter): /On=$($matchingVolume.DriveLetter): /MaxSize=10%"
        Invoke-SentinelOneConfiguration 
    }
}
