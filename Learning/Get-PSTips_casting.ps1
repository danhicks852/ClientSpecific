$castme = 10
$castme | Get-Member
[string]$castme | Get-Member


$castme = "0"
[bool][int]$castme

#explicitly casting a function variable to a specific type will enable autocomplete entries of that type. i.e. Microsoft.BitLocker.BitLockerVolume to use Get-BitLockerVolume
# you can google the function you're using to see what types it uses.