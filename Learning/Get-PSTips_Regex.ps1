#regex
#regexr.com
$string1 = "this is a string to match"
$string1 -match "^.*(s|r)tr"
$Matches[0]
$string2 = "Don't Match me!"
$string2 -match "string to match$"
$Matches[0]
$string3 = "But match me!"
$string3 -match "\w{3} me!$"
$Matches[0]
<#
. = any char except newLine
* is a modifier of the previour expression
| = or
\w means any word character (no symbols, whitespace)
{3} curly braces number next to another token (like \w) match 3
$ = end of string
^ = beginning of the string
#>