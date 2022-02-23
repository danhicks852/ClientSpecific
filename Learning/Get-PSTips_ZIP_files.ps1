#Require powershell version 5
#Requires -Version 5
#Creates a subfolder with zip name.
Expand-Archive -Path c:\path-to-archive.zip
#Creates a custom subfolder
Expand-Archive -Path c:\path-to-archive.zip -DestinationPath c:\destinationfolder

#does not require version 5 (deprecated)
[System.IO.Compression.ZipFile]::ExtractToDirectory("path-to-zip","path-to-directory")

#7zip method
(New-Object System.Net.WebClient).DownloadFile("https://file.provaltech.com/repo/tools/7za.exe",".\7za.exe") | Out-Null
& ".\7za.exe" x ".\zipfile.7z" -olog4j