$randomNumber = Get-Random
$newObject = [PSCustomObject]@{
    Name = $randomNumber
    $randomNumber = "My name is always changing!"
    "this property $randomNumber is just to annoy stephen" = "umadbro"
} 