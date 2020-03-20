<#
.Synopsis
    Updates the build number for installed NAV Components from a specific build in the Windows Registry

.DESCRIPTION
    Scans Windows Registery (Uninstall) on NAV Components with a specific build number and updates this build number to the new build number.

.EXAMPLE
    Update-WinRegNavBuild -OldBuild "10.0.15140.0" -NewBuild "10.0.20784.0"

.PARAMETER OldBuild
    The old NAV build number value you want to upgrade, for example 10.0.15140.0

.PARAMETER NewBuild
    The new NAV build number value you want to write in the Windows registry, for example 10.0.20784.0
#>
function Update-WinRegNavBuild
{
    [CmdletBinding()]
    [Alias()]
    [OutputType()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $OldBuild,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $NewBuild
    )

    Process
    {
        
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$($env:computername))

        $Architectures = @("32", "64")

        foreach ($Architecture in $Architectures) {
    
            if ($Architecture -eq "32") {
                # Reg locations of currently Installed 32bit or 32/64bit programs
                $UninstallKey = "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
            }
            if ($Architecture -eq "64") {
                # Reg locations of currently Installed 64bit programs
                $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
            }

            $Regkey = $Reg.OpenSubKey($UninstallKey)
            $subkeys = $Regkey.GetSubKeyNames()

            foreach ($key in $subkeys) {

                $thisKey = $UninstallKey + "\\" + $key

                $thisSubKey = $Reg.OpenSubKey($thisKey)

                if (($thisSubKey.GetValue("DisplayName") -like "*Microsoft Dynamics NAV*" -or `
                     $thisSubKey.GetValue("DisplayName") -like "*Microsoft Dynamics 365 Business Central*") -and `
                     $thisSubKey.GetValue("DisplayVersion") -eq $oldBuild) {
                
                    $RegPath = 'HKLM:\\{0}' -f $thisKey
                    Set-ItemProperty -Path $RegPath -Name 'DisplayVersion' -Value $newBuild
                    Write-Verbose "Updated $($thisSubKey.GetValue("DisplayName")) from $oldBuild to $newBuild"

                    # Clear InstallSource to prevent a repair installation that will rollback to the old CU

                    Set-ItemProperty -Path $RegPath -Name 'InstallSource' -Value ''

                    if ($($thisSubKey.GetValue("Version")) -eq $oldBuild) {
                        Set-ItemProperty -Path $RegPath -Name 'Version' -Value $newBuild
                    }
                }
            
            } # End foreach subkeys

        } # End foreach architecture

    } # End process

} # End function Update-WinRegNavBuild

Export-ModuleMember -Function Update-WinRegNavBuild


