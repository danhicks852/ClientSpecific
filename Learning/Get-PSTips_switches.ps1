$test1 = 5
switch ($test1) {
    1 {Write-Host "One"}
    2 {Write-Host "Two"}
    3 {Write-Host "Three"}
    4 {Write-Host "Four"}
    5 {Write-Host "Five"}
    default {Write-Host "Default"}
}
$test2 = 5
switch ($test2) {
    1 {Write-Host "One"}
    2 {Write-Host "Two"}
    3 {Write-Host "Three"}
    4 {Write-Host "Four"}
    5 {Write-Host "Five"; break;}
    {$_ -gt 4}{Write-Host "Greater than Four"}
    default {Write-Host "Default"}
}
$test3 = "something","somethingelse",5
switch ($test3) {
    "something" {Write-Host "Well that sure is $($_)! :D"}
    "somethingelse" {Write-Host "You're $($_)! ;)"}
    default {Write-Host "Default"}
}

$test4 = "Lorem ipsum dolar sit amet, consectatur adipiscing elit, sed 1234 do eiusm"
switch -Regex ($test4) {
    "\sipsum\sdolor" {Write-Host "Matched!"}
    "\d+\sdo eiusm$" { Write-Host "Matched #2!" }
    Default { "No match" }
}
