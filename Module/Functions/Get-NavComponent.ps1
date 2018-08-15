<#
.Synopsis
    Scans host system on installed NAV components, installation location and installation details

.DESCRIPTION
    Scans host system on installed NAV components, installation location and installation details

.PARAMETER NavVersion
    The Nav Version, example: '2017', '2018', '2013 R2'

.EXAMPLE
    $NavComponents = Get-NavComponents -NavVersion "2017"

.EXAMPLE
    $NavComponents = Get-NavComponents -NavVersion "2013 R2"
#>
function Get-NAVComponent
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $NavVersion
    )

    Begin
    {   
        # Validate NAV Version and get NAV version

        $nr = Get-NavVersionFolder($NavVersion)
        $NavVersionFolder = $nr.NavVersionFolder
        $NavVersion = $nr.Version

        # Excluded for now: BPA, TestToolKit, UpgradeToolKit, WindowsPowerShellScripts

        $Adcs = New-Object System.Object
        $Adcs | Add-Member -MemberType NoteProperty -Name "Component" -Value "ADCS"
        $Adcs | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV Automated Data Capture System"
        $Adcs | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $Adcs | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $Adcs | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $Adcs | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $Adcs | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $Adcs | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $HelpServer = New-Object System.Object
        $HelpServer | Add-Member -MemberType NoteProperty -Name "Component" -Value "HelpServer"
        $HelpServer | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV $NavVersion Help"
        $HelpServer | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $HelpServer | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $HelpServer | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $HelpServer | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $HelpServer | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $HelpServer | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $Nst = New-Object System.Object
        $Nst | Add-Member -MemberType NoteProperty -Name "Component" -Value "NST"
        $Nst | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV $NavVersion Server"
        $Nst | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $Nst | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $Nst | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $Nst | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $Nst | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $Nst | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $Outlook = New-Object System.Object
        $Outlook | Add-Member -MemberType NoteProperty -Name "Component" -Value "OUTLOOK"
        $Outlook | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV $NavVersion Outlook Add-in"
        $Outlook | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $Outlook | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $Outlook | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $Outlook | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $Outlook | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $Outlook | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $Rtc = New-Object System.Object
        $Rtc | Add-Member -MemberType NoteProperty -Name "Component" -Value "RTC"
        $Rtc | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV $NavVersion RoleTailored Client"
        $Rtc | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $Rtc | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $Rtc | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $Rtc | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $Rtc | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $Rtc | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $WebClient = New-Object System.Object
        $WebClient | Add-Member -MemberType NoteProperty -Name "Component" -Value "WEB CLIENT"
        $WebClient | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "Microsoft Dynamics NAV $NavVersion Web Client"
        $WebClient | Add-Member -MemberType NoteProperty -Name "IsInstalled" -Value $False
        $WebClient | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value ""
        $WebClient | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value ""
        $WebClient | Add-Member -MemberType NoteProperty -Name "InstallSource" -Value ""
        $WebClient | Add-Member -MemberType NoteProperty -Name "Bit" -Value ""
        $WebClient | Add-Member -MemberType NoteProperty -Name "RegKey" -Value ""

        $NavComponents = @( $Adcs,$HelpServer,$Nst,$Outlook,$OutlookServer,$Rtc,$WebClient)

        # Create an instance of the Registry Object and open the HKLM base key
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$($env:computername))
    }

    Process
    {
        Get-NavComponentsFromWinReg
        Get-NavComponentPaths
    }

    End
    {
        return $NavComponents
    }
}

Export-ModuleMember -Function Get-NAVComponent

function Get-NavComponentsFromWinReg
{

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

        # Drill down into the Uninstall key for the corresponding architecture using the OpenSubKey Method
        $Regkey = $Reg.OpenSubKey($UninstallKey)

        Write-Verbose "Reg path for $Architecture bit: $UninstallKey"

        # Retrieve an array of string that contain all the subkey names from the Uninstall registery tree

        $subkeys = $Regkey.GetSubKeyNames()

        # Open each Subkey to check if it's a NAV component

        foreach ($key in $subkeys) {

            $thisKey = $UninstallKey + "\\" + $key

            # Open the subkey

            $thisSubKey = $Reg.OpenSubKey($thisKey)

            # If the regkey doesn't contain a NAV component: continue

            if ($($thisSubKey.GetValue("DisplayName")) -notin $NavComponents.Displayname) {
                continue
            }

            # Match the regkey with the correct NAV components and add the information from the regkey to the nav component array
            foreach ($Component in $NavComponents) {
                if ($Component.Displayname -ne $($thisSubKey.GetValue("DisplayName"))) {
                    continue
                }

                # Workaround for ADCS for not having the NAV version in the display name
                if ($($thisSubKey.GetValue("DisplayVersion")) -notlike "$($NavVersionFolder.Insert(($NavVersionFolder.Length-1),".") + ".")*") {
                    continue
                }

                $Component.DisplayVersion = $($thisSubKey.GetValue("DisplayVersion"))
                $Component.InstallLocation = $($thisSubKey.GetValue("InstallLocation"))
                $Component.InstallSource = $($thisSubKey.GetValue("InstallSource"))
                $Component.RegKey = $thisKey
                $Component.Bit = $Architecture

                #Validate the found component path
                        
                if ($Component.InstallLocation) {
                            
                    if (Test-Path -Path $Component.InstallLocation) {
                        $Component.IsInstalled = $True

                        Write-Verbose ""
                        Write-Verbose "$($Component.Displayname) found"
                        Write-Verbose "File location: $($Component.InstallLocation)" 
                        Write-Verbose "Register location: $($Component.RegKey)"
                        continue

                    } # End if 

                } # End if 

                Write-Verbose ""
                Write-Verbose "$($Component.Displayname) found"
                Write-Verbose "Register location: $($Component.RegKey)"

            } # End foreach component

        } # End foreach subkey

    } # End foreach architecture

} # End function Get-NavComponentsFromWinReg

function Get-NavComponentPaths {     

    foreach ($Component in $NavComponents) {
                
        if ($Component.Component -eq "ADCS") {
            $RegPath = "SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\Automated Data Capture System"
        }

        if ($Component.Component -eq "HelpServer") {
            $RegPath = "SOFTWARE\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\DynamicsNAV100Help"
        }

        if ($Component.Component -eq "NST") {
            $RegPath = "SOFTWARE\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\Service"
        }

        if ($Component.Component -eq "OUTLOOK") {
            $RegPath = "SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\OutlookAddin"
        }

        if ($Component.Component -eq "OUTLOOKSERVER") {
            $RegPath = ""
        }

        if ($Component.Component -eq "RTC") {
            $RegPath = "SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\RoleTailored Client"
        }

        if ($Component.Component -eq "WEB CLIENT") {
            $RegPath = "SOFTWARE\\Microsoft\\Microsoft Dynamics NAV\\$NavVersionFolder\\Web Client"
        }

        $ComponentPath = Get-NavComponentPath ($RegPath)

        if ($ComponentPath) {
            $Component.IsInstalled = $True
            $Component.InstallLocation = $ComponentPath
        }

        Clear-Variable RegPath
        Clear-Variable ComponentPath
    }

} # End function GetNavComponentPaths

function Get-NavComponentPath ($RegPath) {
            
    $RegKey = $Reg.OpenSubKey($RegPath)
            
    if ($RegKey) {
                
        if ($($RegKey.GetValue("Path"))) {
                    
            if (Test-Path -Path $($RegKey.GetValue("Path"))) {
                        
                $ComponentPath = $RegKey.GetValue("Path")
                return $ComponentPath
            }
        }
    }
            
    $ComponentPath = $False
    return $ComponentPath

} # End function GetNavComponentPath