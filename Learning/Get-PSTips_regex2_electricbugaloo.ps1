#Regex Capture Groups
#A capture group means "find anything of X property in this", its the stuff inside parenthesis
#(A|B|C|D|E|R) is a capture group
#
#In powershell, when you do Capture Group, it adds those Capture groups inside the Matches[] array in the order of capture.

Get-CimInstance -ClassName win32_loggedonuser | ForEach-Object {
    $_.Antecedent -match 'Name = "(.+)", Domain = "(.+)"' | Out-Null
    #first array object is full match
    #subsequent array objects are the capture groups
    $Matches[0]
    "$($Matches[2])\$($Matches[1])"
}
