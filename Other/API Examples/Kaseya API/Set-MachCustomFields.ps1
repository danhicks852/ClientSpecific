<#[CmdletBinding()]
 param (
    [Parameter(Mandatory)][string]$Token,
    [Parameter(Mandatory)][string]$URL
)#>
$Token = "dXNlcj1kYW50ZXN0YXBpLHBhc3MyPTgxMmY4NmQxZGNhZWI5NDg4MzJjYjdiMTcxNmFlODViNDhhNjRiZjViMTI4YjQ0YWMwZjdiM2I2Y2MwMTkxYTgscGFzczE9OWNjZTlhNTlhZGQ0ZDk1MTZmNDFmMWQ2N2M4OGE2MzhhMTA1MTY0NSxycGFzczI9YzUxMmZlNmZkMTI0MGI3ZDg4ZTMwMmZlNjI2M2JkMGIyZGQzYmM1OGNjNzdlMWMwOTMyNjg0NjcxODY1YzUxZCxycGFzczE9ZDU4M2NiYmQ5MmIyZDVlNThkMjRjY2VmM2NjOWVlYjYyMTAyMjM4NyxyYW5kMj0yNjIxNjg1MQ=="
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

