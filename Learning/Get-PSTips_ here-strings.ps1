$type = "string"
$herestring = ` #the grave ("`") allows a break to a new line. (escapes the new line)
@"
this
is
a
single
$type
"@

$herestring[0]
$herestring
$htmlString = `
@"
<html>
    <body>
        <span> Hello world from a "here-string"!</span>
    </body>
</html>
"@ | Out-File ".\herestringhello.html"
& ".\herestringhello.html"
$htmlString
$linebreakString = "this`nis`na`nstring"
$linebreakString