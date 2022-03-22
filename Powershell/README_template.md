# Overview
Explain the problem this content solves.

# Requirements
Does the content require any additional data or configuration to operate?

# Process
How does the content operate and accomplish the goal?

# Payload Usage
Describe how the payload is executed and if it requires any parameters. Delete the parameter block below if not needed. State that this does not use a payload if it doesn’t.

Explanation of the usage of the below example.

```powershell
.\somescript.ps1 -Param1 param
```

# Parameters
| Parameter         | Alias | Required  | Default   | Type      | Description                               |
| ----------------- | ----- | --------- | --------- | --------- | ----------------------------------------- |
| `AParameter`      | `a`   | True      |           | String    |                                           |
| `BParameter`      | `b`   | True      |           | Int       |                                           |
| `CParameter`      | `c`   | False     | `"dd"`    | String    |                                           |
| `DParameter`      | `d`   | True      |           | Int       |                                           |
| `EParameter`      | `e`   | False     | `False`   | Bool      |                                           |

# Output
Location of output for log, result, and error files.

    .\MyProject-log.txt
    .\MyProject-data.txt
    .\MyProject-error.txt