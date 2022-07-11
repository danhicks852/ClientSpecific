#Configure Paramaters and validate input if needed.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
    [Parameter(Mandatory = $true)][Alias ('p')][String]$APIPass,
    [Parameter(Mandatory = $true)][Alias ('u')][String]$APIUser
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
}
else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
#endregion template
#region functions
function RandomNumberGen([int]$numberOfDigits) {
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

$machCFArray = @(
    'xPVAL BitLocker',`
    'xPVAL DFS Monitor',`
    'xPVAL 3rd Party Install Server',`
    'xPVAL Drive List',`
    'xPVAL 3rd Party Update Server',`
    'xPVAL Exchange',`
    'xPVAL Exclude from Antivirus',`
    'xPVAL Exclude from EXG Monitoring',`
    'xPVAL Exclude from Monitoring',`
    'xPVAL Exclude from Patching',`
    'xPVAL Hyper-V Manager',`
    'xPVAL Monitoring Managed',`
    'xPVAL MS Office Version',`
    'xPVAL Org Name',`
    'xPVAL OS Install Date',`
    'xPVAL OS Build',`
    'xPVAL Asset Recovery',`
    'xPVAL Patch Schedule',`
    'xPVAL Antivirus Managed',`
    'xPVAL Primary Domain Controller',`
    'xPVAL Remote Settings',`
    'xPVAL SQL Server',`
    'xPVAL 3rd Party Install WS',`
    'xPVAL System Restore Date',`
    'xPVAL 3rd Party Update WS',`
    'xPVAL WS Acting as Server',`
    'xPVAL Server Acting as WS',`
    'xPVAL Windows 10 Build Result',`
    'xPVAL Webroot Status',`
    'xPVAL SentinelOne Status'`
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
}
Write-Log -Text "Authenticating with Kaseya VSA..." -Type LOG
$rawRESTAuthResponse = Invoke-RestMethod -Uri $server"/api/v1.0/auth" -Headers $headers -Method 'GET'
$RESTBearer = $rawRESTAuthResponse.Result.Token
if (!($RESTBearer)) {
    Write-Log -Text "Authentication was not successful" -Type ERROR
    Write-Log -Text $rawRestAuthResponse -Type ERROR
    exit
}
else {
    Write-Log -Text "Authentication Successful" -Type LOG
    Write-Host "REST API Bearer Token: $RESTBearer"
    $RESTheaders = @{
        Authorization = "Bearer $RESTBearer"
    }
}
foreach ($field in $machCFArray){
    $body = "FieldName=$field&FieldType=string"
    $Response = Invoke-RestMethod -Uri "$Server/api/v1.0/assetmgmt/assets/customfields" -Headers $RESTheaders -Body $body -Method 'POST' -ErrorAction Continue
    Write-Log -Text "Writing CF $field" -Type LOG
}