<#
.SYNOPSIS
    Sets the endpoint hostname per Ciracom policy
.EXAMPLE
    PS C:\> Set-CiracomHostName.ps1 -Agent prlptus04.mainoffice.proval
.PARAMETER Agent
    The full agent name, passed in from VSA
.PARAMETER Server
    The base URL of the target VSA.
.PARAMETER APIUser
    The username for the API user. Must have "Data Warehouse" scope
.PARAMETER APIPass
    The password for the API user. Used for REST API. Sent encrypted. Must have REST scope.
.OUTPUTS
    Set-CiracomHostName-data.txt
    Set-CiracomHostName-log.txt
.NOTES
    API credentials should be stored in Managed Variables.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$Agent,
    [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
    [Parameter(Mandatory = $true)][Alias ('p')][String]$APIPass,
    [Parameter(Mandatory = $true)][Alias ('u')][String]$APIUser
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

# Write your code here

function Invoke-restAPIAuth {
    param (
        [Parameter(Mandatory = $true)][Alias ('s')][String]$Server,
        [Parameter(Mandatory = $true)][Alias ('p')][String]$APIPass,
        [Parameter(Mandatory = $true)][Alias ('u')][String]$APIUser
    )
    #https://help.kaseya.com/webhelp/EN/RESTAPI/9050000/EN_restapiguide_R95.pdf
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
    Write-Log -Text "Authenticating with Kaseya VSA..." -Type LOG
    $rawRESTAuthResponse = Invoke-RestMethod -Uri $server"/api/v1.0/auth" -Headers $headers
    $RESTBearer = $rawRESTAuthResponse.Result.Token
    if (!($RESTBearer)) {
        Write-Log -Text "Authentication was not successful" -Type ERROR
        Write-Log -Text $rawRestAuthResponse -Type ERROR
        exit
    }
    else {
        Write-Log -Text "Authentication Successful" -Type LOG
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
    #needed for REST API Authentication
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
$RESTBearer = Invoke-restAPIAuth -S $Server -U $APIUser -P $APIPass
$RESTheaders = @{
    Authorization = "Bearer $RESTBearer"
    Method        = "GET"
}
Write-Log -Text "Finding a matching org from the API..."
$shortname = $agent.Split(".")[0]
$org = $agent.Split(".")[2]
$Response = Invoke-RestMethod -Uri "$Server/api/v1.0/system/orgs" -Headers $RESTheaders
$orgShortName = $Response.Result.OrgRef
$serial = Get-CIMInstance -Classname win32_bios | Select-Object -ExpandProperty Serialnumber
$hostname = "$orgShortName-$serial"
Write-Host $hostname

