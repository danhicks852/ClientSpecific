
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
}
else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT

}$acCheck = Test-Path (Join-Path ${env:ProgramFiles(x86)} (Join-Path 'Cisco' 'Cisco AnyConnect Secure Mobility Client'))
if ($acCheck) {
    Invoke-WebRequest -Uri https://file.provaltech.com/repo/kaseya/clients/ahead/GlobalProtect.msi -OutFile "$PSScriptRoot\GlobalProtect.msi"
    Start-Process msiexec.exe -Wait -ArgumentList "/i $PSScriptRoot\GlobalProtect.msi /norestart /quiet /L*V '$PSScriptRoot\gp.log'"
}