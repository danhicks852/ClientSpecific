<#
.SYNOPSIS
    Creates an L2TP VPN connection within Windows UI with user=provided parameters
.EXAMPLE
    PS C:\>Add-CustomVPNConnection.ps1 -VpnName 'VPN Connection' -ServerAddress 'vpn.contoso.com' -L2tpPsk 'adsf87q34*&^yuiyg)' -SetEncapsulation
.PARAMETER VpnName
    Friendly Name of the VPN connection created in Windows
.PARAMETER ServerAddress
    URL or IP of the VPN server accepting the connection
.PARAMETER L2tpPsk
    L2TP Passkey provided by the VPN administrator
.PARAMETER L2tpPsk
    If enabled, adds DWORD: AssumeUDPEncapsulationContextOnSendRule = 2 to HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent\ to prevent VPN issues behind double NAT.
.OUTPUTS
    Add-CustomVPNConnection-log.txt
    Add-CustomVPNConnection-ERROR.txt
.NOTES
    Will always create an L2TP VPN client with Require Encryption and EAP auth. VPN connection will be created for all users.
    Sample: Add-VpnConnection -AllUserConnection -Name "itSynergy VPN" -ServerAddress vpn.itsynergy.com -TunnelType L2tp -EncryptionLevel Required -AuthenticationMethod Eap -L2tpPsk '"-C9\"37e]0N<|\@^498(t9~y&d"' -Force -PassThru
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$VpnName,
    [Parameter(Mandatory = $true)][string]$ServerAddress,
    [Parameter(Mandatory = $true)][string]$L2tpPsk,
    [Parameter(Mandatory = $false)][switch]$SetEncapsulation
)

### Bootstrap ###
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
}

else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
Add-VpnConnection -AllUserConnection -Name $VpnName -ServerAddress $ServerAddress -TunnelType L2tp -EncryptionLevel Required -AuthenticationMethod Eap -L2tpPsk "$L2tpPsk" -Force
if ($SetEncapsulation) {
    if (!(Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent\' -Name 'AssumeUDPEncapsulationContextOnSendRule')) {
        New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent -Name AssumeUDPEncapsulationContextOnSendRule -Value 2
    }

    else {
        Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent -Name AssumeUDPEncapsulationContextOnSendRule -Value 2
    }
}

Add-VpnConnection -TunnelType