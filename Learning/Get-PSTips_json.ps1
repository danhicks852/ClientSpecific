$content = Get-CimInstance -ClassName win32_computersystem | ConvertTo-Json
#[System.Environment]::CurrentDirectory = (Get-Location).Path
[IO.File]::WriteAllLines("$((Get-Location).Path)\JSONTest.json", $content)
$readContent = ConvertFrom-JSON -InputObject ((Get-content ".\JSONTest.json" -Raw) -join "")
$readContent