if (-not $bootstrapLoaded) {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://file.provaltech.com/repo/script/Bootstrap.ps1')
    Set-Environment
} else {
    Write-Log -Text 'Bootstrap already loaded.' -Type INIT
}
function Get-BinaryType {
    [CmdletBinding(  
        SupportsShouldProcess = $false,
        ConfirmImpact = "none",
        DefaultParameterSetName = ""
    )]
    param(
        [Parameter(
            HelpMessage = "Enter binary file(s) to examine",
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_.FullName })]
        [IO.FileInfo[]]
        $Path,
        [Alias("PassThru")]
        [switch]
        $PassThrough
    )
    begin {
        try {
            #add the enum for the binary types
            #Using more user friendly names since they won't likely be used outside this context
            Add-Type "
                    public enum BinaryType 
                    {
                        BIT32 = 0, // A 32-bit Windows-based application,           SCS_32BIT_BINARY
                        DOS   = 1, // An MS-DOS – based application,            SCS_DOS_BINARY
                        WOW   = 2, // A 16-bit Windows-based application,           SCS_WOW_BINARY
                        PIF   = 3, // A PIF file that executes an MS-DOS based application, SCS_PIF_BINARY
                        POSIX = 4, // A POSIX based application,                SCS_POSIX_BINARY
                        OS216 = 5, // A 16-bit OS/2-based application,              SCS_OS216_BINARY
                        BIT64 = 6  // A 64-bit Windows-based application,           SCS_64BIT_BINARY
                    }"
        }
        catch {} #type already been loaded, do nothing
        try {
            # create the win32 signature
            $Signature = 
            '
                        [DllImport("kernel32.dll")]
                        public static extern bool GetBinaryType(
                            string lpApplicationName,
                            ref int lpBinaryType
                        );
                    '
            # Create a new type that lets us access the Windows API function
            Add-Type -MemberDefinition $Signature `
                -Name                 BinaryType `
                -Namespace             Win32Utils
        }
        catch {} #type already been loaded, do nothing
    }

    process {
        foreach ($Item in $Path) {
            $ReturnedType = -1
            Write-Verbose "Attempting to get type for file: $($Item.FullName)"
            $Result = [Win32Utils.BinaryType]::GetBinaryType($Item.FullName, [ref] $ReturnedType)

            #if the function returned $false, indicating an error, or the binary type wasn't returned
            if (!$Result -or ($ReturnedType -eq -1)) {
                Write-Error "Failed to get binary type for file $($Item.FullName)"
            }
            else {
                $ToReturn = [BinaryType]$ReturnedType
                if ($PassThrough) {
                    #get the file object, attach a property indicating the type, and passthru to pipeline
                    Get-Item $Item.FullName -Force |
                    Add-Member -MemberType noteproperty -Name BinaryType -Value $ToReturn -Force -PassThru 
                }
                else { 
                    #Put enum object directly into pipeline
                    $ToReturn 
                }
            }
        }
    }
}
$dir = Get-CIMInstance -Classname Win32_product | Where-Object {$_.Name -like '*Global*'}
Get-BinaryType "$($dir.InstallLocation)\SWGVC.exe" | out-file $PSScriptRoot\bit.txt
$dir.Version |Out-File $PSScriptRoot\ver.txt