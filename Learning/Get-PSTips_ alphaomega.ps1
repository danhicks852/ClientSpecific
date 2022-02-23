function Invoke-BeginTest {
    [CmdletBinding()]
    param ([Parameter(ValueFromPipeline=$true)][string[]]$StringInput)
    begin {
        Write-Host "We're beginning with $($StringInput.Count)"

    }

    process {

        return $_

    }

    end {

        Write-Host "Now we're out."

    }

}



function Invoke-BeginTest2 {

    [CmdletBinding()]

    param ([Parameter(ValueFromPipeline=$true)][string[]]$StringInput)

    begin {

        Write-Host "BeginTest2"

    }

    process {

        $var = 0

        return $var++

    }

    end {

        Write-Host "Now we're out."

    }

}



("this","is","a","test") | Invoke-BeginTest | Invoke-BBeginTest2