Invoke-WebRequest -Uri 'https://download.schneider-electric.com/files?p_File_Name=pcbe.zip&p_Doc_Ref=APC_PCBE_1005_EN&p_enDocType=Software+-+Release' -OutFile "$($PSScriptRoot)\pcbe.zip"
Invoke-WebRequest -Uri 'https://file.provaltech.com/repo/tools/7z.exe' -OutFile "$($PSScriptRoot)\7z.exe" 
& ./7z.exe x $PSScriptRoot\pcbe.zip -oc:$PSScriptRoot\pcbe -r
& ./7z.exe x $PSScriptRoot\pcbe\pcbesetup.exe -0c:$PSScriptRoot\pcbe -r 


