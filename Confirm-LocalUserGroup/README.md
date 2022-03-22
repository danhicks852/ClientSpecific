# Overview
Checks for a local user group within a security and writes the result to data log

# Requirements
None

# Process
uses Get-LocalGroupMember and looks through each group for subgroups

# Payload Usage

```powershell
c:\> Confirm-LocalUserAccount.ps1 -username USER
```

# Parameters
| Parameter         | Alias | Required  | Default   | Type      | Description                               |
| ----------------- | ----- | --------- | --------- | --------- | ----------------------------------------- |
| `Username  `      |       | True      |           | String    |                                           |

# Output
Location of output for log, result, and error files.

    .\Confirm-LocalUserAccount-log.txt
    .\Confirm-LocalUserAccount-data.txt
    .\Confirm-LocalUserAccount-error.txt