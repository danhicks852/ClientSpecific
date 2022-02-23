<#
[CmdletBinding()]
 param (
    [Parameter(Mandatory)][string]$Username,
    [Parameter(Mandatory)][String]$Password,
    [Parameter(Mandatory)][string]$URL
)
#>

$Username = "dantestapi"
$password = "!gkf?B36x25rTq*!"
$URL = "https://vsa.provaltech.com"
$getUserReportsCommand = $PSScriptRoot+"\Get-KaseyaUsers.ps1"
$setMachFieldCommand = $PSScriptRoot+"\Set-MachCustomFields.ps1"
function RandomNumberGen([int]$numberOfDigits) {
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $numbers = [byte[]]::new($numberOfDigits * 2)
    $rng.GetNonZeroBytes($numbers)
    $result = ""
    for($i = 0; $i -lt $numberOfDigits; $i++) {
        $result += $numbers[$i].ToString()
    }
    $result = $result -replace "0",""
    $result.Substring(1,$numberOfDigits)
}

function CalculateHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$HashingAlgorithm
    )
    [byte[]]$arrByte = $null
    if($HashingAlgorithm -eq "SHA-1") {
        $hash = [System.Security.Cryptography.SHA1Managed]::new()
        $arrByte = $hash.ComputeHash([System.Text.ASCIIEncoding]::ASCII.GetBytes($Value))
    } elseif ($HashingAlgorithm -eq "SHA-256") {
        $hash = [System.Security.Cryptography.SHA256Managed]::new()
        $arrByte = $hash.ComputeHash([System.Text.ASCIIEncoding]::ASCII.GetBytes($Value))
    }
    $s = ""
    foreach($byte in $arrByte) {
        $s += $byte.ToString("x2")
    }
    return $s
}

function Show-Menu {
    do {
    Clear-Host
    Write-Host "================ Select API Operation ================"
    
    Write-Host "1: Press '1' to generate User, Role, and Scope Reports."
    Write-Host "2: Set Machine Custom Fields"
    Write-Host "t: Print Token"
    Write-Host "Q: Press 'Q' to quit."
    $selection = Read-Host "Please make a selection"
    switch ($selection){
            '1'{
                Get-UserReports
            }
            '2'{
                Set-Fields
            }
            't'{
                Write-Host $token
                Read-Host
            }
            'q'{
                return 
            }
        }
        
    }until ($selection -eq 'q')
}


function Get-UserReports {
    Write-Host "Getting Users list from API"
    Invoke-Expression "$getUserReportsCommand $AuthArgs"
}

function Set-Fields {
    Write-Host "Setting Machine Custom Fields"
    Invoke-Expression "$SetMachFieldCommand $AuthArgs"
}
Write-Host "Generating Authentication Payload"
$randomNumber = RandomNumberGen -numberOfDigits 8
$RawSHA256Hash = CalculateHash -Value $Password -HashingAlgorithm "SHA-256"
$CoveredSHA256Hash = CalculateHash -Value ($Password + $Username) -HashingAlgorithm "SHA-256"
$CoveredSHA256Hash = CalculateHash -Value ($CoveredSHA256Hash + $randomNumber) -HashingAlgorithm "SHA-256"
$RawSHA1Hash = CalculateHash -Value $Password -HashingAlgorithm "SHA-1"
$CoveredSHA1Hash = CalculateHash -Value $($Password + $Username) -HashingAlgorithm "SHA-1"
$CoveredSHA1Hash = CalculateHash -Value $($CoveredSHA1Hash + $randomNumber) -HashingAlgorithm "SHA-1"
$payload = [System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes("user=$username,pass2=$CoveredSHA256Hash,pass1=$CoveredSHA1Hash,rpass2=$RawSHA256Hash,rpass1=$RawSHA1Hash,rand2=$randomNumber"))
$headers = @{
    Authorization="Basic $payload"
    Method="GET"
}
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
Write-Host "Authenticating with Kaseya VSA"
Invoke-RestMethod -Uri $url"/api/v1.0/auth" -Headers $headers
$AuthArgs = "-Token $token -URL $URL"
Write-Host "Successfully Authenticated."
Show-Menu