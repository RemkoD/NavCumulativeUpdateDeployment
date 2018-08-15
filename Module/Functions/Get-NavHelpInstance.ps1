<#
.Synopsis
    Scans Internet Information Service (IIS) on configured NAV Help Server and returns result.'
.DESCRIPTION
    Scans Internet Information Service (IIS) on configured NAV Help Server and returns result.

.EXAMPLE
    $WebServerInstances = Get-NAVHelpInstance -NavVersion "2017"

.EXAMPLE
    $WebServerInstances = Get-NAVHelpInstance -NavVersion "2013 R2"

.PARAMETER NavVersion
	# The installed NAV Version where you want to import the module from. For example: NAV2016, NAV2017 or NAV2018
#>
function Get-NAVHelpInstance
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param
    (
        # 
        [Parameter(Mandatory=$true)]
        [string]$NavVersion
    )

    Begin
    {
        # Validate NAV Version and get NAV version

        $nr = Get-NavVersionFolder($NavVersion)
        $NavVersionFolder = $nr.NavVersionFolder
        $NavVersion = $nr.Version

        # Default Web Server Name

        $WebServerName = "Microsoft Dynamics NAV $NavVersion Help"
        

        # TODO: Check if commandlet Get-Website is available, if not import WebAdministration
        Import-Module WebAdministration -Force
        $IIS_WebSite = Get-Website | Select-Object -Property name, applicationPool, physicalPath | where name -eq $WebServerName
    }

    Process
    {
        $HelpServerComponent = Get-NavComponent -NavVersion 2017 | where Component -eq 'HelpServer'

        $HelpInstances = @()
    
        # Get all folders from IIS root folder
    
        $Folders = Get-ChildItem -Path $($HelpServerComponent.InstallLocation) | Where-Object { $_.PSIsContainer } | Select-Object Name,FullName

        if (-not $Folders) {
            break
        }

        foreach ($Folder in $Folders) {
        
            $dll = $Folder.FullName + '\bin\Microsoft.Dynamics.Nav.WebHelp.dll'
        
            if (-not (Test-Path -Path $dll)) {
                continue
            }

            $FileVersion = (Get-Item $dll).VersionInfo.FileVersion

            <#
                Check if the found instance is from the same NAV Version.
                Example:
                    Version: 2017
                    NAVFolderVersion: 100
                    Build: 10.0.20784.0
                    Compair the first two characters of the version with the first two characters of the build.
            #>

            if ($NavVersionFolder.substring(0,2) -ne $FileVersion.substring(0,2)) {
                continue
            }

            $obj = New-Object System.Object
            $obj | Add-Member -MemberType NoteProperty -Name "Website" -Value "Microsoft Dynamics NAV $NavVersion Help"
            $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $FileVersion
            #$obj | Add-Member -MemberType NoteProperty -Name "HelpServerInstance" -Value $Folder.Name
             
            if (Test-Path -Path $($Folder.FullName + '\')) {
                
                $obj | Add-Member -MemberType NoteProperty -Name "InstancePath" -Value $($Folder.FullName + '\')
            }

            if (Test-Path -Path $($Folder.FullName + '\web.config')) {

                $obj | Add-Member -MemberType NoteProperty -Name "ConfigurationFile" -Value $($Folder.FullName + '\web.config')
            }

            if ($IIS_WebSite.physicalPath -eq $Folder.FullName) {
                $obj | Add-Member -MemberType NoteProperty -Name "ApplicationPool" -Value $IIS_WebSite.applicationPool
            }

            $HelpInstances += $obj
            Clear-Variable obj
        }

    }

    End
    {
        return $HelpInstances
    }
}

Export-ModuleMember -Function Get-NavHelpInstance