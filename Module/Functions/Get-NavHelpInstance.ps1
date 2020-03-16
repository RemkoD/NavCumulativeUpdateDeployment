<#
.Synopsis
    Scans Internet Information Service (IIS) on configured NAV Help Server and returns result.'

.DESCRIPTION
    Scans Internet Information Service (IIS) on configured NAV Help Server and returns result.

.EXAMPLE
    $WebServerInstances = Get-NAVHelpInstance -NavVersion "bc150"
.EXAMPLE
    $WebServerInstances = Get-NAVHelpInstance -NavVersion "nav2013 R2"

.PARAMETER NavVersion
	# The installed NAV Version where you want to import the module from. For example: NAV2016, NAV2017 or NAV2018
#>
function Get-NAVHelpInstance
{
    [CmdletBinding()]
    [OutputType([array])]
    Param
    (
        # 
        [Parameter(Mandatory=$true)]
        [string] $NavVersion
    )

    Begin
    {
        # Validate NAV Version and get NAV version
        [hashtable] $NavVersion = Get-NavVersionFolder -NavVersion $NavVersion

        # Default Web Server Name

        if($NavVersion.ProductAbb -eq 'BC'){
            $WebServerName = 'Microsoft Dynamics 365 Business Central Help'
        }
        if($NavVersion.ProductAbb -eq 'NAV'){
            $WebServerName = 'Microsoft Dynamics NAV {0} Help' -f $NavVersion.Version
        }

        # Check if the module WebAdministration is pressent. This usually is default available from IIS 7.5 and higher and on Windows Server 2016 or Windows 10 and higher.
        # On Windows 2012 R2 systems and older with IIS 

        if ( -not (Get-Command Get-WebApplication -errorAction SilentlyContinue)) {
            
            # Import the module if it is available

            $Module = Get-Module -List WebAdministration
            
            if($Module) {
                Import-Module WebAdministration -Force
            } else {
                #ToDo: Use Write-Error
                Write-Host "`nPowershell module WebAdministration is missing." -ForegroundColor Red
                Write-Host "If Internet Information Service (IIS) is installed on this machine, make sure the WebAdministration module is enabled." -ForegroundColor Yellow
                Write-Host "If this machine doesn't have the Internet Information Service (IIS) installed you can ignore this message." -ForegroundColor Yellow
            }

        }

        # TODO: Check if commandlet Get-Website is available, if not import WebAdministration
        Import-Module WebAdministration -Force
        $IIS_WebSite = Get-Website | Select-Object -Property name, applicationPool, physicalPath | Where-Object -Property name -eq $WebServerName
    }

    Process
    {
        if($NavVersion.ProductAbb -eq 'BC'){
            $HelpServerComponent = Get-NavComponent -NavVersion $NavVersion.Version | Where-Object -Property Component -eq 'HelpServer'
        }
        if($NavVersion.ProductAbb -eq 'NAV'){
            $HelpServerComponent = Get-NavComponent -NavVersion ('{0}{1}' -f $NavVersion.ProductAbb, $NavVersion.Version) | Where-Object -Property Component -eq 'HelpServer'
        }

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

            if ($NavVersion.NavVersionFolder.substring(0,2) -ne $FileVersion.substring(0,2)) {
                continue
            }

            $obj = New-Object System.Object
            $obj | Add-Member -MemberType NoteProperty -Name "Website" -Value  $WebServerName
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