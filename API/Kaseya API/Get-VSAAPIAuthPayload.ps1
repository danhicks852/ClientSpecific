[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$Username,
    [Parameter(Mandatory)][string]$Password
)
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

$randomNumber = RandomNumberGen -numberOfDigits 8
$RawSHA256Hash = CalculateHash -Value $Password -HashingAlgorithm "SHA-256"
$CoveredSHA256Hash = CalculateHash -Value ($Password + $Username) -HashingAlgorithm "SHA-256"
$CoveredSHA256Hash = CalculateHash -Value ($CoveredSHA256Hash + $randomNumber) -HashingAlgorithm "SHA-256"
$RawSHA1Hash = CalculateHash -Value $Password -HashingAlgorithm "SHA-1"
$CoveredSHA1Hash = CalculateHash -Value $($Password + $Username) -HashingAlgorithm "SHA-1"
$CoveredSHA1Hash = CalculateHash -Value $($CoveredSHA1Hash + $randomNumber) -HashingAlgorithm "SHA-1"
[System.Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes("user=$username,pass2=$CoveredSHA256Hash,pass1=$CoveredSHA1Hash,rpass2=$RawSHA256Hash,rpass1=$RawSHA1Hash,rand2=$randomNumber"))
