<#[CmdletBinding()]
 param (
    [Parameter(Mandatory)][string]$Token,
    [Parameter(Mandatory)][string]$URL
)#>
$Token = "MC55VkErQVNYclRJZ1lZYy9xcjdoNkdzSU9jMitJOUNxcVpXK1FFNGdRZ1pxbXFIYUx2Rk5HQy9LYkYxWDZuUFJMaE1HTVZ5YW0vT3FHS04zWExObkowdz09"
$URL = "https://vsa.provaltech.com"
$headers = @{
    Authorization = "Bearer $Token"
}
$CFGetResult = Invoke-RestMethod -Uri "https://vsa.provaltech.com/api/v1.0/assetmgmt/assets/customfields" -Method "GET" -Headers $headers
foreach ($result in $CFGetResult.result<# | Where-Object "xPVAL" -match $result.FieldName#>) {
    #Eventually need to only pull xpval results from ProVal VSA.
    $result = $result | ConvertTo-Json
    $result = $result.replace('{"FieldName": ', '{"key": "FieldName", "value": ')
    Write-Host $result
    <#

JSON output looks like this: 
 {
  "FieldName": "xPVAL WS Acting as Server",
  "FieldType": "string"
}

Body needs to look like this
{"key": "FieldName", "value": "TestField"}
,
{"key": "FieldType", "value": "string"}

 The raw object output looks like this: 
 @{FieldName=xPVAL WS Acting as Server; FieldType=string}


#>

    $CFPostResult = Invoke-RestMethod -Uri "$URL/api/v1.0/assetmgmt/assets/customfields" -Method "POST" -Headers $headers -body $body -ContentType "application/x-www-form-urlencoded"
}

