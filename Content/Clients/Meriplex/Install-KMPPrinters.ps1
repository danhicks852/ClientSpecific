<#
.SYNOPSIS
    Installs Front and Back office KMP printers by Store Number. Store number is dynamically retreived from endpoint hostname.
.EXAMPLE
    ./Install-KMPPrinters.ps1

#Configure Paramaters and validate input if needed.
#>
### Bootstrap ###
#The bootstrap loads Logging, Chocolatey, environment paths, common variables, powershell updates. It should be included on ALL ProVal powershell scripts developed.
if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
####BEGIN ACTUAL SCRIPT######
$siteObject = [PSCustomObject]@{
    '1831' = '89'
    '1101' = '231'
    '1102' = '232'
    '1104' = '233'
    '1105' = '234'
    '1106' = '235'
    '1112' = '236'
    '1113' = '237'
    '1115' = '239'
    '1116' = '240'
    '1117' = '241'
    '1118' = '242'
    '1119' = '243'
    '1401' = '245'
    '1402' = '246'
    '1403' = '247'
    '1404' = '248'
    '1407' = '249'
    '1409' = '51'
    '1410' = '52'
    '1413' = '53'
    '1414' = '54'
    '1501' = '55'
    '1508' = '56'
    '1509' = '57'
    '1515' = '58'
    '1520' = '60'
    '1521' = '61'
    '1527' = '98'
    '1601' = '64'
    '1602' = '65'
    '1603' = '66'
    '1604' = '67'
    '1605' = '68'
    '1608' = '159'
    '1616' = '70'
    '1801' = '72'
    '1803' = '73'
    '1804' = '74'
    '1807' = '76'
    '1808' = '77'
    '1809' = '78'
    '1810' = '79'
    '1811' = '80'
    '1812' = '81'
    '1813' = '82'
    '1814' = '83'
    '1815' = '84'
    '1817' = '85'
    '1819' = '86'
    '1827' = '96'
    '0202' = '122'
    '0203' = '94'
    '0204' = '123'
    '0205' = '124'
    '0206' = '125'
    '0207' = '126'
    '0208' = '127'
    '0209' = '128'
    '0210' = '129'
    '0211' = '130'
    '0212' = '131'
    '0213' = '132'
    '0214' = '133'
    '0215' = '134'
    '0217' = '136'
    '0218' = '137'
    '0219' = '138'
    '0220' = '139'
    '0221' = '69'
    '0223' = '141'
    '0224' = '142'
    '0226' = '143'
    '0227' = '116'
    '0228' = '168'
    '0229' = '90'
    '0231' = '99'
    '0233' = '95'
    '0301' = '144'
    '0302' = '145'
    '0303' = '146'
    '0304' = '147'
    '0305' = '148'
    '0306' = '149'
    '0307' = '151'
    '0309' = '152'
    '0311' = '153'
    '0312' = '154'
    '0313' = '155'
    '0316' = '156'
    '0317' = '91'
    '0601' = '179'
    '0602' = '180'
    '0603' = '181'
    '0604' = '182'
    '0605' = '183'
    '0607' = '184'
    '0608' = '185'
    '0609' = '186'
    '0610' = '187'
    '0612' = '188'
    '0614' = '189'
    '0615' = '190'
    '0617' = '191'
    '0618' = '192'
    '0620' = '193'
    '0621' = '194'
    '0622' = '195'
    '0623' = '196'
    '0624' = '163'
    '0625' = '164'
    '0626' = '177'
    '0801' = '200'
    '0802' = '201'
    '0803' = '202'
    '0804' = '203'
    '0805' = '204'
    '0806' = '175'
    '0807' = '174'
    '0808' = '205'
    '0809' = '206'
    '0810' = '207'
    '0811' = '208'
    '0812' = '209'
    '0813' = '92'
    '0814' = '210'
    '0816' = '115'
    '0817' = '211'
    '0818' = '212'
    '0819' = '213'
    '0820' = '214'
    '0821' = '215'
    '0822' = '216'
    '0824' = '172'
    '0825' = '173'
    '0826' = '97'
    '0903' = '220'
    '0906' = '221'
    '0907' = '222'
    '0908' = '223'
    '0909' = '224'
    '0910' = '225'
    '0911' = '226'
    '0917' = '227'
    '0918' = '228'
    '0919' = '71'
    '0920' = '229'
    '0921' = '230'
    '0922' = '117'
    '0923' = '59'
    '0991' = '169'
    '0992' = '170'
    '0993' = '171'
    '0995' = '251'
    '0996' = '252'
    '0997' = '255'
    '0998' = '253'
    '0999' = '254'
    '1103' = '176'
    '1114' = '238'
    '1121' = '119'
    '1122' = '93'
    '1502' = '88'
    '1525' = '158'
    '1802' = '75'
    '1821' = '87'
    '1825' = '160'
    '1830' = '161'
}
Write-Log -Text 'Downloading Drivers' -Type LOG
(New-Object System.Net.WebClient).DownloadFile("https://file.provaltech.com/repo/kaseya/clients/meriplex/prntdrv.zip","$PSScriptRoot\prntdrv.zip")
Write-Log -Text 'Unpacking Drivers' -Type LOG
Expand-Archive -LiteralPath "$PSScriptRoot\prntdrv.zip" -DestinationPath "$PSScriptRoot\drivers" -Force
Remove-Item -Path "$PSScriptRoot\prntdrv.zip"
Write-Log -Text 'Setting IP Addresses:' -Type LOG
Write-Log -Text "Back Office IP: '10.'+$secondOctet+'.20.131'" -Type LOG
Write-Log -Text "Front Office IP: '10.'+$secondOctet+'.20.130'" -Type LOG
$secondOctet = ($siteObject | Select-Object -ExpandProperty $ENV:COMPUTERNAME.Substring(0,4))
$backOfficeIP =  '10.'+$secondOctet+'.20.131'
$frontOfficeIP = '10.'+$secondOctet+'.20.130'
Write-Log -Text 'Checking if the Back Office port exists, and creating it if it does not' -Type LOG
$portExist = Get-Printerport -Name $backOfficeIP -ErrorAction SilentlyContinue
if (-not $portExist) { Add-PrinterPort -Name $backOfficeIP -PrinterHostAddress $backOfficeIP }
Write-Log -Text 'Installing all HP UPDs' -Type LOG
& pnputil.exe /add-driver "$PSScriptRoot\drivers\prntdrv\*.inf"
Add-PrinterDriver -Name 'HP Universal Printing PCL 6'
Write-Log -Text 'Adding Back Office Printer' -Type LOG
Add-Printer -DriverName 'HP Universal Printing PCL 6' -Name 'Back Office Printer' -PortName $backOfficeIP
Write-Log -Text 'Checking if the Front Office port exists, and creating it if it does not' -Type LOG
$portExist = Get-Printerport -Name $frontOfficeIP -ErrorAction SilentlyContinue
if (-not $portExist) { Add-PrinterPort -Name $frontOfficeIP -PrinterHostAddress $frontOfficeIP }
Write-Log -Text 'Adding Front Office Printer' -Type LOG
Add-PrinterDriver -Name 'HP Universal Printing PCL 6'
Add-Printer -DriverName 'HP Universal Printing PCL 6' -Name 'Front Office Printer' -PortName $frontOfficeIP




