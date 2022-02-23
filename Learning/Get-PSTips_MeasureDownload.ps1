#Measure-Command -Expression {Get-Help MeasureCommand} | Select-Object -ExpandProperty TotalMilliseconds | Write-Host
#Measure command measures the amount of time it takes to run a command in milliseconds
Write-Host "Measuring IWR"
Measure-Command -Expression {
    #always use basic parsing
    Invoke-WebRequest -UseBasicParsing -Uri "https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-win64.zip" -OutFile .\speedtest.zip
} | Select-Object -ExpandProperty TotalMilliseconds | Write-Host
#MULTIPLE PIPES ZOMG
Remove-Item .\speedtest.zip
Write-Host "Measuring IWR without progress indicator"
Measure-Command -Expression {
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing -Uri "https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-win64.zip" -OutFile .\speedtest.zip
    $ProgressPreference = "Continue"
} | Select-Object -ExpandProperty TotalMilliseconds | Write-Host
Remove-Item .\speedtest.zip
Write-Host "Measuring WebClient"
Measure-Command -Expression {
    (New-Object System.Net.WebClient).DownloadFile("https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-win64.zip",".\speedtest.zip")
} | Select-Object -ExpandProperty TotalMilliseconds | Write-Host
Remove-Item .\speedtest.zip