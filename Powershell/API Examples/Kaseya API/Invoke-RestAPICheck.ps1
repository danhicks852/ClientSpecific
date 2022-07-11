[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
    [Parameter(Mandatory = $true)][Alias ('t')][String]$DWToken,
    [Parameter(Mandatory = $true)][Alias ('p')][String]$APIPass,
    [Parameter(Mandatory = $true)][Alias ('u')][String]$APIUser
)
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
}
else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
function Invoke-DataWarehouseRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
        [Parameter(Mandatory = $true)][Alias ('t')][String]$DWToken,
        [Parameter(Mandatory = $true)][Alias ('u')][String]$User
    )
    $creds = "$user`:$DWToken"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
    $headers = @{
        Authorization = "Basic $encodedCreds"
        Method        = "GET"
    }
    $rawResponse = Invoke-RestMethod -Uri "$Server/api/odata/1.0/Agents?top=3" -Headers $headers
    return $rawResponse.Value
}
function Invoke-restAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
        [Parameter(Mandatory = $true)][Alias ('p')][String]$RESTBearer
    )
    $RESTheaders = @{
        Authorization = "Bearer $RESTBearer"
        Method        = "GET"
    }
    $Response = Invoke-RestMethod -Uri "$Server/api/v1.0/assetmgmt/agents?top=3" -Headers $RESTheaders
    return $Response.Result
}
function Invoke-restAPIAuth {
    param (
        [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
        [Parameter(Mandatory = $true)][Alias ('p')][String]$APIPass,
        [Parameter(Mandatory = $true)][Alias ('u')][String]$APIUser
    )
    $randomNumber = RandomNumberGen -numberOfDigits 8
    $RawSHA256Hash = CalculateHash -Value $APIPass -HashingAlgorithm "SHA-256"
    $CoveredSHA256Hash = CalculateHash -Value ($APIPass + $APIUser) -HashingAlgorithm "SHA-256"
    $CoveredSHA256Hash = CalculateHash -Value ($CoveredSHA256Hash + $randomNumber) -HashingAlgorithm "SHA-256"
    $RawSHA1Hash = CalculateHash -Value $APIPass -HashingAlgorithm "SHA-1"
    $CoveredSHA1Hash = CalculateHash -Value $($APIPass + $APIUser) -HashingAlgorithm "SHA-1"
    $CoveredSHA1Hash = CalculateHash -Value $($CoveredSHA1Hash + $randomNumber) -HashingAlgorithm "SHA-1"
    $payload = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes("user=$APIUser,pass2=$CoveredSHA256Hash,pass1=$CoveredSHA1Hash,rpass2=$RawSHA256Hash,rpass1=$RawSHA1Hash,rand2=$randomNumber"))
    $headers = @{
        Authorization = "Basic $payload"
        Method        = "GET"
    }
    Write-Log -Text "Authenticating with Kaseya REST API..." -Type LOG
    $rawRESTAuthResponse = Invoke-RestMethod -Uri $server"/api/v1.0/auth" -Headers $headers
    $RESTBearer = $rawRESTAuthResponse.Result.Token
    if (!($RESTBearer)) {
        Write-Log -Text "REST API Authentication was not successful" -Type ERROR
        Write-Log -Text $rawRestAuthResponse -Type ERROR
        exit
    }
    else {
        Write-Log -Text "REST API Authentication Successful" -Type LOG
        Write-Host "REST API Bearer Token: $RESTBearer"
    }
    return $RESTBearer
}
function RandomNumberGen([int]$numberOfDigits) {
    #needed for REST API Authentication
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $numbers = [byte[]]::new($numberOfDigits * 2)
    $rng.GetNonZeroBytes($numbers)
    $result = ""
    for ($i = 0; $i -lt $numberOfDigits; $i++) {
        $result += $numbers[$i].ToString()
    }
    $result = $result -replace "0", ""
    $result.Substring(1, $numberOfDigits)
}
function CalculateHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$HashingAlgorithm
    )
    [byte[]]$arrByte = $null
    if ($HashingAlgorithm -eq "SHA-1") {
        $hash = [System.Security.Cryptography.SHA1Managed]::new()
        $arrByte = $hash.ComputeHash([System.Text.ASCIIEncoding]::ASCII.GetBytes($Value))
    }
    elseif ($HashingAlgorithm -eq "SHA-256") {
        $hash = [System.Security.Cryptography.SHA256Managed]::new()
        $arrByte = $hash.ComputeHash([System.Text.ASCIIEncoding]::ASCII.GetBytes($Value))
    }
    $s = ""
    foreach ($byte in $arrByte) {
        $s += $byte.ToString("x2")
    }
    return $s
}
$RESTBearer = Invoke-RestAPIAuth -Server $Server -APIPass $APIPass -APIUser $APIUser
$restResult = Invoke-restAPIRequest -Server $Server -RESTBearer $RESTBearer
$dwResult = Invoke-DataWarehouseRequest -Server $Server -User $APIUser -DWToken $DWToken
if(!($restResult)){
    Write-Log -Text "Authentication to the REST API was succesful, however no data was returned."
}
else {
    $restResult.AgentName | Sort-Object  | Select-Object -First 3
}
if(!($dwResult)){
    Write-Log -Text "Authentication to the Data Warehouse API was succesful, however no data was returned."
}
else {
    $dwResult.AgentName | Sort-Object  | Select-Object -First 3
}
Write-Host "If the two results above show different data, investigate."
