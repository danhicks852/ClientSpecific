# Enabled Settings

The following settings are what the ProVal current standards are for PowerShell code. These standards may change overtime, but will not deviate from what is available via the PSAnalyzer. For detailed information about these settings, refer to the reference link under each entry.

To automatically format a document in VS Code, press `Ctrl` + `Shift` + `P` to open the Command Palette, search for `Format Document` and press Enter.

![How to Format a Document](/res/format_document.gif)

## PSAvoidUsingDoubleQuotesForConstantString
[AvoidUsingDoubleQuotesForConstantString.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/AvoidUsingDoubleQuotesForConstantString.md)

We do not want to put constant strings in double quotes. Exceptions to this rule exist and are illustrated in the above link.

### Wrong

```powershell
function Get-Sammie {
    return "A yummy sammie"
}
```

### Correct
```powershell 
function Get-Sammie {
    return 'A yummy sammie'
}
```

### Correct
```powershell 
function Get-Sammie {
    $sammie = 'sammie'
    return "A yummy $sammie"
}
```

## PSPlaceOpenBrace
[PlaceOpenBrace.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/PlaceOpenBrace.md)

Open braces should be on the same line as the preceding keyword.

### Wrong

```powershell
function Get-Sammie
{
    return 'A yummy sammie'
}
```

### Correct
```powershell 
function Get-Sammie {
    return 'A yummy sammie'
}
```

## PSPlaceCloseBrace
[PlaceCloseBrace.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/PlaceCloseBrace.md)

A close brace should not have empty lines or other symbols before it, unless it is a one-line block.

### Wrong

```powershell
function Get-Sammie {
    return 'A yummy sammie'

}
```

### Wrong #2

```powershell
function Get-Sammie {
    return 'A yummy sammie' }
```

### Correct

```powershell
function Get-Sammie {
    return 'A yummy sammie'
}
```

### Correct #2

```powershell
function Get-Sammie { return 'A yummy sammie' }
```

## PSUseCorrectCasing
[UseCorrectCasing.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/UseCorrectCasing.md)

PowerShell cmdlets should use their correct casing for readablilty. Currently PSAnalyzer does not do this for custom functions, but you are expected to follow the standards for built-in cmdlets with your oen functions.

### Wrong

```powershell
function get-sammie {
    return 'A yummy sammie'
}
```

### Correct

```powershell
function Get-Sammie {
    return 'A yummy sammie'
}
```

## PSUseConsistentWhitespace

[UseConsistentWhitespace.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/UseConsistentWhitespace.md)

We want whitespace to be consistent across scripts. The following items are validated:

- Checks if there is a space after the opening brace and a space before the closing brace.
```powershell
# Wrong
function Get-Sammie {return 'A yummy sammie'}

# Correct
function Get-Sammie { return 'A yummy sammie' }
```

- Checks if there is a space between a keyword and its corresponding open brace. 
```powershell
# Wrong
function Get-Sammie{ return 'A yummy sammie' }

# Correct
function Get-Sammie { return 'A yummy sammie' }
```

- Checks if there is space between a keyword and its corresponding open parenthesis.
```powershell
# Wrong
if('sammie') { return 'yum' }

# Correct
if ('sammie') { return 'yum' }
```

- Checks if a binary or unary operator is surrounded on both sides by a space.
```powershell
# Wrong
$sammie='yum'

# Correct
$sammie = 'yum'
```

- Checks if a comma or a semicolon is followed by a space.
```powershell
# Wrong
@('bacon','cheese','bread')

# Correct
@('bacon', 'cheese', 'bread')

# Wrong
$sammie = 'yum';return $sammie

# Correct
$sammie = 'yum'; return $sammie
```

- Checks if a pipe is surrounded on both sides by a space and only one space.
```powershell
# Wrong
Get-Sammie| Invoke-Sammie

# Wrong
Get-Sammie  |  Invoke-Sammie

# Correct
Get-Sammie | Invoke-Sammie
```

## PSUseConsistentIndentation
[UseConsistentIndentation.md](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/UseConsistentIndentation.md)

We want to use spaces for indentation and each indent should be 4 spaces. Indentation for pipelines should only be one indent deep.

### Wrong
```powershell
function Get-Sammie {
  return 'A yummy sammie'
}
```

### Correct
```powershell
function Get-Sammie {
    return 'A yummy sammie'
}
```

### Wrong
```powershell
Get-Sammie |
Invoke-Sammie
```

### Wrong
```powershell
Get-Sammie |
    Invoke-Sammie |
        Set-Sammie
```

### Correct
```powershell
Get-Sammie |
    Invoke-Sammie |
    Set-Sammie
```
