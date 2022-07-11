[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string] $username,
    [Parameter(Mandatory = $false)][string] $portal_client_code,
    [Parameter(Mandatory = $false)][string] $itglue_client_id
)
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
### Process ###
#endregion template

$version = '1.0.2.0'
$username = 'qlocal'
$portal_client_code = '721A-4BE8-92AA'
# $itglue_client_id = 'ENTER ITGLUE CLIENT ID' (passed in via param)
$computer_name_prefix = 'PC-'
$password_len = 24
Write-Log -Text "`n#################################################`n#`n# input values:`n#`tusername: $username`n#`tportal client code: $portal_client_code`n#`titglue client location ID: $itglue_client_id`n#`n# if any of these values are incorrect or missing`n# change them within the script`n#`n#################################################`n`n"

# encodes utf8 to base64
function encodeToBase64 {
    param ($enc_txt)
    return [Convert]::ToBase64string($enc_txt);
}

# decodes base64 to utf8
function decodeFromBase64 {
    param ($b64_txt)
    return [System.Convert]::FromBase64String($b64_txt);
}

# packs arguments into json object
function packJson {
    param ($user, $pass, $comp, $code, $client_id, $call_type)
    return @{username = $user; password = $pass; computer_name = $comp; client_code = $code; client_location_id = $client_id; call_type = $call_type = 'POST'; key = '4qwPJoMmarfHDHp'; version = $version } | ConvertTo-Json
}

# generate random password as string
function createPassword {
    param ($password_len)
    $password = -join ((33..33) + (35..38) + (42..42) + (50..57) + (63..72) + (74..75) + (77..78) + (80..90) + (97..104) + (106..107) + (109..110) + (112..122) | Get-Random -Count $password_len | ForEach-Object { [char]$_ })
    return $password
}

# create new LocalUser give proper username and pass
function setUser {
    param ($username, $password)
    $localAdmin = Get-LocalUser | Where-Object { $_.Name -eq $username }
    $sec_password = ConvertTo-SecureString -String $password -AsPlainText -Force
    if (-not $localAdmin) {
        Write-Log -Text "New Admin added to Machine: $username and generated password" -TYPE LOG
        New-LocalUser "$username" -Password $sec_password -FullName "$username" -Description 'Galactic local admin'
        Add-LocalGroupMember -Group 'Administrators' -Member "$username"
    } else {
        Write-Log -Text "Updated existing Admin on Machine: $username and set new password"-TYPE LOG
        Set-LocalUser -Name $username -Password $sec_password
    }
}

# given any text and the pubKey, encrypts text
function encryptRsa {
    param ($textToEnc, $rsaPubKey)

    [byte[]] $bytes = decodeFromBase64 $rsaPubKey

    [int]$firstExpSize = 11
    [int]$lastExpSize = 14
    [byte[]] $expCountBytes = $bytes[$lastExpSize..$firstExpSize] #read in reverse due to big/little eidian conversion

    [int]$firstExpByte = $lastExpSize + 1
    [int]$lastExpByte = $lastExpSize + [bitconverter]::ToInt32($expCountBytes, 0)
    [byte[]] $exponent = $bytes[$firstExpByte..$lastExpByte]

    [int]$firstModSize = $lastExpByte + 1;
    [int]$lastModSize = $firstModSize + 3;
    [byte[]] $modulusCountBytes = $bytes[$lastModSize..$firstModSize] #read in reverse due to big/little eidian conversion

    [int]$firstModByte = $lastModSize + 1;
    [int]$lastModByte = $firstModByte + [bitconverter]::ToInt32($modulusCountBytes, 0);
    [byte[]] $modulus = $bytes[$firstModByte..$lastModByte]

    [int] $ignoreCount = -1

    while ($modulus[$ignoreCount + 1] -eq 0x00) {
        $ignoreCount += 1
    }

    if ($ignoreCount -gt -1) {
        $start = $ignoreCount + 1
        $end = $modulus.Length
        $modulus = $modulus[$start..$end]
    }

    [System.Security.Cryptography.RSACryptoServiceProvider] $rsaPub = New-Object System.Security.Cryptography.RSACryptoServiceProvider(4096)
    [System.Security.Cryptography.RSAParameters] $rsaParms = New-Object System.Security.Cryptography.RSAParameters
    $rsaParms.Exponent = $exponent
    $rsaParms.Modulus = $modulus
    $rsaPub.ImportParameters($rsaParms)
    $bytesToEnc = [System.Text.Encoding]::UTF8.GetBytes($textToEnc)

    return $rsaPub.Encrypt($bytesToEnc, [System.Security.Cryptography.RSAEncryptionPaddingMode]::oaep)
}

# checks for default parameters and if run as admin
function errorHandler {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Log -Text "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!" -TYPE ERROR
        exit
    }
    if ($portal_client_code -eq 'ENTER YOUR PORTAL CLIENT CODE') {
        Write-Log -Text 'please enter your Portal Client Code on the script and re-run' -TYPE ERROR
        exit
    }
    if ($itglue_client_id -eq 'ENTER ITGLUE CLIENT ID') {
        Write-Log -Text 'please enter your ITGlue Client ID and re-run' -TYPE ERROR
        exit
    }
    if ($username -eq 'ENTER USERNAME') {
        -TYPE ERROR
        Write-Log -Text 'please enter desired local admin username and re-run' -TYPE ERROR
        exit
    }
}

# MAIN EXECUTION

errorHandler


$computername = $computer_name_prefix + [Environment]::MachineName

[string] $rsaPubKey = 'AAAAB3NzaC1yc2EAAAABJQAAAgEAgk3GdIBiJ9ihpYByjDE1ncNL8Q6eVzhYqGk/nhnoSMKdomBonn+ps6SQHczpBz7L4Mesb3fwOZv7vvCyzAK0UW+tZ6DxYXdMJlwO0IIJz35qmqbmHJDGiTgRikuCzrjxkbMaJMVebb7/bo+5gDqaQ4Ppce2kF4IDcP6yClAGj4fHddsDD/vrWsuJFj84rjuU/oIF8NVJ4ingl2knhOspMMRBEX1ZsD+Ov4i7cHkQTpuQGGNVvxYiDkJuNwCdJ4N4AQpczgnVVI4m8kIFMpOvIDCv7v0j6KGqWUYU+I/Bcqq+z1uG8sqECiGAd77wcuPfoR1s7VdBMeJ4+zA3mVVtB0OAfYlFFrBr2traoeDFucZ4kJ1ieY0vQfH7JBC5ZB/vXXmm8oVywfdtX5OwzItIrEZn6ucgRjKs6qjTtd+Zpm45oCPy706zGm8R84gC0sMNP6ZD+XBCZbcmtOWNewUFSrGa5vqMzqtShBCSvYcu9hVjtRbrGuDYz1/ie1f0xdcFnNCDeX2jKmL2LOQBlkgw+dtXUS233hc4F7uaR/IWYiA50tLe+3HK/rMSgFVTIjJO1puynVtQroBzy5ZTj1b9LBwa+lkKDKAkWR7TqE9h9Gjd8jDDUpSu0Xf9a6Dqz3N1FqLeHtHobSrPeCiXxeB+javxaHdKmLxdyXGb106jbVk='

$password = createPassword($password_len)

$enc_user_bytes = encryptRSA $username $rsaPubKey
$enc_user = encodeToBase64($enc_user_bytes)

$enc_pass_bytes = encryptRSA $password $rsaPubKey
$enc_pass = encodeToBase64($enc_pass_bytes)

$enc_comp_bytes = encryptRSA $computername $rsaPubKey
$enc_comp = encodeToBase64($enc_comp_bytes)

function Get-UrlStatusCode() {
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] 'Tls12,Tls13'
        $response = Invoke-WebRequest -Uri https://portal.galacticscan.com/api/externalUser -UseBasicParsing -Method POST -Body $jsonObj -ContentType 'application/json' -Headers $headers
        $responseObj = ConvertFrom-Json $response
        if ($responseObj.success -ne 'true') {
            if ($responseObj.type -eq 'version') {
                Write-Log -Text 'unsucessful response from galactic api: '$responseObj.message -TYPE LOG
                return 401
            } elseif ($responseObj.type -eq 'client_code') {
                Write-Log -Text 'unsucessful response from galactic api: '$responseObj.message -TYPE LOG
                return 402
            } elseif ($responseObj.type -eq 'api_key') {
                Write-Log -Text 'unsucessful response from galactic api: '$responseObj.message -TYPE LOG
                return 403
            } elseif ($responseObj.type -eq 'url') {
                Write-Log -Text 'unsucessful response from galactic api: '$responseObj.message -TYPE LOG
                return 404
            } elseif ($responseObj.type -eq 'gal_api') {
                Write-Log -Text 'unsucessful response from galactic api: '$responseObj.message -TYPE LOG
                Write-Log -Text 'did not upload local admin password to itglue!'
                return 405
            } elseif ($responseObj.type -eq 'itg_api') {
                Write-Log -Text 'unsucessful response from itglue api: '$responseObj.message -TYPE LOG
                Write-Log -Text 'failed to upload local admin password to itglue!' -TYPE LOG
                Write-Log -Text "is the 'password access' box check next to youy key in ITGlue UI?" -TYPE LOG
                Write-Log -Text 'is your itglue api key uploaded to galactic portal?' -TYPE LOG
                return 406
            } else {
                Write-Log -Text 'uncaught error: '$responseObj.message -TYPE LOG
                Write-Log -Text 'failed to upload local admin password to itglue!' -TYPE LOG
                return 422
            }
        }
        if ($responseObj.success -eq 'true') {
            Write-Log -Text $responseObj.message -TYPE LOG
            return 200
        }
    } catch [System.Net.WebException] {
        Write-Log -Text 'invoke-webrequest failed: local admin user not uploaded to itglue, local admin not created on machine' -TYPE LOG
        Write-Log -Text "$_.Exception.Response" -TYPE ERROR
        exit 1
    }
}

$headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
$headers.Add('Accept', 'application/json')
$jsonObj = packJson $enc_user $enc_pass $enc_comp $portal_client_code $itglue_client_id
$statusCode = Get-UrlStatusCode
if ($statusCode -eq 200) {
    Write-Log -Text "created local admin account $username" -TYPE LOG
    setUser $username $password
    exit 0
} else {
    Write-Log -Text 'credentials were not stored' -TYPE ERROR
    exit 1
}
