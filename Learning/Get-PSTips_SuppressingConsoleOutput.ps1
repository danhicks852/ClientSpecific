function Write-Host {} #overwrites the Write-host in lower than version 5, as it did not use 6 stream like it does now.
MyFunction(.1) 2>$null 6>$null
# 2 is error stream
# 6 is info stream
Out-Null # takes success string (1) and does nothing with it.