[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$Token,
    [Parameter(Mandatory)][string]$URL
)
$headers = @{
    Authorization = "Bearer $Token"
    Method        = "GET"
}

$path = "$PSScriptRoot\UserReports"
New-Item -Path $PSScriptRoot -Name "UserReports" -ItemType "directory"
$UserResponse = Invoke-RestMethod -Uri "$URL/api/v1.0/system/users" -Headers $headers

#TODO: Figure out how to expand sub-arrays into strings, and put them back into the $_.Result.AdminScopeIDs, 
#      compare to roles results, and fill readable role / scope names in the spreadsheet

$UserResponse.Result | Export-Csv $path"\UserList.csv"

$RoleResponse = Invoke-RestMethod -Uri "$URL/api/v1.0/system/roles" -Headers $headers
$RoleResponse.Result | Export-Csv $path"\Roles.csv"

$ScopeResponse = Invoke-RestMethod -Uri "$URL/api/v1.0/system/scopes" -Headers $headers
$ScopeResponse.Result | Export-Csv $path"\Scopes.csv"