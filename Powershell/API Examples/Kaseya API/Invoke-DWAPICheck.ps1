[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
    [Parameter(Mandatory = $true)][Alias ('t')][String]$DWToken,
    [Parameter(Mandatory = $true)][Alias ('u')][String]$User
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
$creds = "$user`:$DWToken"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
$headers = @{
    Authorization = "Basic $encodedCreds"
    Method        = "GET"
}
Write-Log -Text "Executing Query $Server/api/odata/1.0/Agents?..." -Type LOG
$rawResponse = Invoke-RestMethod -Uri "$Server/api/odata/1.0/Agents?" -Headers $headers
if(!($rawResponse.value)){
    Write-Log -Text "Authentication was successful, but the response contained no data. Possible API issues." -Type ERROR
}
else {
Write-Host $rawResponse.Value
}