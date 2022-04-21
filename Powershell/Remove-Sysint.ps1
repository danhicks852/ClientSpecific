Remove-Item -Path C:\sysint -Recurse -Force -ErrorAction SilentlyContinue
$leftovers = Get-ChildItem C:\sysint -Recurse | Get-Member | Where-Object {$_.TypeName -eq 'System.IO.FileInfo' -and $_.Definition -match "^string PSChildName=KLOG"}
$filename = $leftovers.definition -replace "string PSChildName=",""
$interimFileName = $filename -replace "KLOG","KCTR"
$collectorName = $interimFileName -replace ".csv",""
logman stop $collectorName
logman delete $collectorName
Remove-Item -Path C:\sysint -Recurse -Force