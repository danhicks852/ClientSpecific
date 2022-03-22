# While Galactic Advisors LLC make every effort to deliver high quality products,
# we do not guarantee that our products are free from defects. Our software is provided
# “as is," and you use the software at your own risk. We make no warranties as to
# performance, merchantability, fitness for a particular purpose, or any other warranties
# whether expressed or implied. No oral or written communication from or information provided
# by Galactic Advisors LLC shall create a warranty. Under no circumstances shall
# Galactic Advisors LLC be liable for direct, indirect, special, incidental, or
# consequential damages resulting from the use, misuse, or inability to use this software,
# even if Galactic Advisors LLC has been advised of the possibility of such damages.

Function Write-LogMessage {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
    [switch]$IsError
  )
  if ($IsError.IsPresent) {
    New-WinEvent -LogName "Application" `
      -Source "RMMWindows10Upgrade" `
      -EntryType Error `
      -EventID 42042 `
      -Message "$(Get-date -Format 'MM/dd/yyyy HH:mm K') [ERROR] $message"
    Write-Verbose "$(Get-date -Format 'MM/dd/yyyy HH:mm K') [ERROR] $message"
  }
  else {
    New-WinEvent -LogName "Application" `
      -Source "RMMWindows10Upgrade" `
      -EntryType Information `
      -EventID 42042 `
      -Message "$(Get-date -Format 'MM/dd/yyyy HH:mm K') [INFO] $message"
    Write-Verbose "$(Get-date -Format 'MM/dd/yyyy HH:mm K') [INFO] $message"
  }
}
Function New-Windows10EventSource {
  try {
    New-WinEvent -LogName "Application" `
      -Source "RMMWindows10Upgrade" `
      -ErrorAction Stop
  }
  catch {
    Write-LogMessage -Message "Summary of Actions - Set Up Windows Event Log Source`r`nEvent Log Source already registered."
  }
  Limit-WinEvent -LogName "Application" -MaximumSize 1GB
}
Function Remove-BuildNotificationRestrictions {
  $returnVal = $true
  $logEntry = ""
  $basePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\"
  $fileNames = (
    "Windows10UpgraderApp.exe",
    "Windows10Upgrader.exe",
    "WindowsUpdateBox.exe",
    "SetupHost.exe",
    "setupprep.exe",
    "EOSNotify.exe",
    "MusNotifyIcon.exe",
    "MusNotification.exe"
  )
  foreach ($file in $fileNames) {
    if (Test-Path "$($basePath)$($file)") {
      $logEntry = $logEntry + "Found $($file) in IFEO, removing.`r`n"
      Remove-Item -Path "$($basePath)$($file)"
      if (Test-Path "$($basePath)$($file)") {
        $returnVal = $false
        Write-LogMessage -Message "Failed to remove existing Registry Key $($basePath)\$file " -IsError
      }
    }
  }
  Write-LogMessage -Message "Summary of Actions - Removing Build Restrictions`r`n$($logEntry)"
  return $returnVal
}
Function Remove-OldUpgrades {
  $logMessage = ""
  $returnVal = $true
  $folders = ("_Windows_FU", "Windows10Upgrade")
  foreach ($folder in $folders) {
    if (Test-Path -Path "$($env:SystemDrive)\$folder") {
      $logMessage = $logMessage + "Found $($env:SystemDrive)\$folder... Removing`r`n"
      Remove-Item -Recurse -Path "$($env:SystemDrive)\$folder" -Force
      if (Test-Path -Path "$($env:SystemDrive)\$folder") {
        Write-LogMessage -Message "Failed to remove existing folder $($env:SystemDrive)\$folder " -IsError
        $returnVal = $false
      }
    }
  }
  Write-LogMessage -Message "Summary of Actions - Removing Old Upgrades`r`n$($logMessage)"
  return $returnVal
}
Function Test-FreeSpace {
  $filter = "DeviceID='$($env:SystemDrive)'"
  If (!((Get-CIMInstance -ClassName Win32_LogicalDisk -Filter $filter | select-object -expand freespace) / 1GB -ge 23)) {
    Write-LogMessage -Message "Insufficient Free Space available to perform Upgrade, 23 GB is required" -IsError
    return $false
  }
  return $true
}
Function Test-License {
  #Not a big fan of Doing it this way, but it's a lot easier/faster than the alternatives
  $returnVal = $false
  if ((cscript "$($env:windir)\system32\\slmgr.vbs" /dli) -match "Licensed") {
    $returnVal = $true
  }
  else {
    Write-LogMessage -Message "Windows 10 requires a valid license to upgrade with this tool" -IsError
  }
  return $returnVal
}
Function Get-WindowsUpgradeDiagnosticLog {
  $dir = "$($env:SystemDrive)\Windows10Upgrade"

  New-Item -ItemType directory -Path $dir -ErrorAction SilentlyContinue

  $webClient = New-Object System.Net.WebClient
  $url = 'https://go.microsoft.com/fwlink/?linkid=870142'
  $file = "$($dir)\SetupDiag.exe"
  $webClient.DownloadFile($url, $file)
  $install = Start-Process -FilePath $file -ArgumentList "/Output:$($dir)\SetupResults.log" -Wait -PassThru
  $hex = "{0:x}" -f $install.ExitCode
  $exit_code = "0x$hex"
  # Convert hex code to human readable
  $message = Switch ($exit_code) {
    "0x0" { "SUCCESS: Process started."; break }
    default { "WARNING: Unknown exit code."; break }
  }
  Write-LogMessage "$message (Code: $($exit_code))`r`n$(Get-Content $($dir)\SetupResults.log)" -IsError
}
Function New-Windows10Install {
  $ErrorActionPreference = "SilentlyContinue"
  $dir = "$($env:SystemDrive)\_Windows_FU\packages"
  New-Item -ItemType directory -Path $dir
  Start-Sleep -Second 2
  $webClient = New-Object System.Net.WebClient
  $url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
  $file = "$($dir)\Win10Upgrade.exe"
  $webClient.DownloadFile($url, $file)
  $logMessage = ""
  if (!(Test-Path -Path $dir)) {
    $logMessage = $logMessage + "Unable to Create Directory $($dir)`r`n"
  }
  if (!(Test-Path -Path $file)) {
    $logMessage = $logMessage + "Unable to Download file $($file)`r`n"
  }
  if ($logMessage -match "Unable") {
    Write-LogMessage -Message $logMessage -IsError
    Exit 1
  }
  Write-LogMessage -Message "All tests Passed. Beginning Installation."
  $install = Start-Process -FilePath $file -ArgumentList "/quietinstall /skipeula /auto upgrade /copylogs $dir /migratedrivers all" -Wait -PassThru
  $install.ProcessorAffinity = 7
  $install.PriorityClass = "High"
  $hex = "{0:x}" -f $install.ExitCode
  $exit_code = "0x$hex"
  # Convert hex code to human readable
  $message = Switch ($exit_code) {
    "0xC1900210" { "SUCCESS: No compatibility issues detected"; break }
    "0xC1900101" { "ERROR: Driver compatibility issue detected. https://docs.microsoft.com/en-us/windows/deployment/upgrade/resolution-procedures"; break }
    "0xC1900208" { "ERROR: Compatibility issue detected, unsupported programs:`r`n$incompatible_programs`r`n"; break }
    "0xC1900204" { "ERROR: Migration choice not available." ; break }
    "0xC1900200" { "ERROR: System not compatible with upgrade." ; break }
    "0xC190020E" { "ERROR: Insufficient disk space." ; break }
    "0x80070490" { "ERROR: General Windows Update failure, try the following troubleshooting steps`r`n- Run update troubleshooter`r`n- sfc /scannow`r`n- DISM.exe /Online /Cleanup-image /Restorehealth`r`n - Reset windows update components.`r`n"; break }
    "0xC1800118" { "ERROR: WSUS has downloaded content that it cannot use due to a missing decryption key."; break }
    "0x80090011" { "ERROR: A device driver error occurred during user data migration."; break }
    "0xC7700112" { "ERROR: Failure to complete writing data to the system drive, possibly due to write access failure on the hard disk."; break }
    "0xC1900201" { "ERROR: The system did not pass the minimum requirements to install the update."; break }
    "0x80240017" { "ERROR: The upgrade is unavailable for this edition of Windows."; break }
    "0x80070020" { "ERROR: The existing process cannot access the file because it is being used by another process."; break }
    "0xC1900107" { "ERROR: A cleanup operation from a previous installation attempt is still pending and a system reboot is required in order to continue the upgrade."; break }
    "0x3" { "SUCCESS: The upgrade started, no compatibility issues."; break }
    "0x5" { "ERROR: The compatibility check detected issues that require resolution before the upgrade can continue."; break }
    "0x7" { "ERROR: The installation option (upgrade or data only) was not available."; break }
    "0x0" { "SUCCESS: Upgrade started."; break }
    default { "WARNING: Unknown exit code."; break }
  }
  if ($exit_code -eq "0xC1900210" -or $exit_code -eq "0x3" -or $exit_code -eq "0x0") {
    Write-LogMessage -Message $message
    Start-Sleep -Seconds 300
    Restart-Computer -Force
  }
  else {
    Write-LogMessage -Message $message -IsError
  }
}
#The Magic happens here
New-Windows10EventSource
Remove-BuildNotificationRestrictions | Out-Null
Remove-OldUpgrades | Out-Null
if (!$(Test-FreeSpace) -or !$(Test-License)) {
  Exit 1
}
New-Windows10Install
Start-Sleep -Seconds 120
Get-WindowsUpgradeDiagnosticLog
