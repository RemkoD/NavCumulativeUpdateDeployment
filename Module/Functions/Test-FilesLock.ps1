<#
.Synopsis
    Test files from supplied folder on locks. 

.DESCRIPTION
    Tests all files from the supplied folder recursively if they are available to write. Returns a list of files that are not writeable, locked by other processes.

.EXAMPLE
    $PathsToCheck = @('C:\Temp\FolderA', 'C:\Temp\FolderB')
    Test-FilesLock -Path $PathsToCheck

.EXAMPLE
    Test-FilesLock -Path "C:\Temp\FolderA"

.PARAMETER Path
    One or more parent folder paths. Items in these folders will be validated if they are writeable.
#>
function Test-FilesLock
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $Path
    )

    Begin
    {
        [array] $LockedFiles = @()

    }
    Process
    {
        foreach ($p in $Path) {

            $files = Get-ChildItem -Path $p -Recurse -File | Select-Object -Property FullName 
            
            foreach ($file in $files) {

                if (-not (Test-FileLock -Path $file.FullName)) {
                    
                    # File is not locked

                    Write-Verbose "Not Locked: $($file.FullName)"
                    continue
                }

                # File is locked
                
                Write-Verbose " Is Locked: $($file.FullName)"
                $LockedFiles += $file.FullName
            }
        }
    }
    End
    {
        if ($LockedFiles.Count -ge 1) {
            
            return $LockedFiles
        }

        return $false
    }
}

Export-ModuleMember -Function Test-FilesLock

# https://social.technet.microsoft.com/Forums/windowsserver/en-US/74ea3752-9403-4296-ab98-d03fcc12b608/how-to-check-to-see-if-a-file-is-openlocked-before-trying-to-copy-it?forum=winserverpowershell
function Test-FileLock {

    param (
        [parameter(Mandatory=$true)]
        [string]$Path
    )

    $oFile = New-Object System.IO.FileInfo $Path

    try
    {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($oStream)
        {
            $oStream.Close()
        }
        $false
    }
    catch
    {
        # file is locked by a process.
        $true
    }
}

