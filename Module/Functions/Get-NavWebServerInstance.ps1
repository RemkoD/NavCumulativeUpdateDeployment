<#
.Synopsis
    Scans Internet Information Service (IIS) on configured NAV Web Clients and returns result.

.DESCRIPTION
    Scans Internet Information Service (IIS) on configured NAV Web Clients and returns result.

.EXAMPLE
    $WebServerInstances = Get-NavWebServerInstance -NavVersion "2017"

.EXAMPLE
    $WebServerInstances = Get-NavWebServerInstance -NavVersion "2013 R2"

.PARAMETER NavVersion
    The Nav Version, example: '2017', '2018', '2013 R2'
#>
function Get-NavWebServerInstance
{
    [CmdletBinding()]
    [Alias()]
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
            $WebServerName = 'Microsoft Dynamics 365 Business Central Web Client'
        }
        if($NavVersion.ProductAbb -eq 'NAV'){
            $WebServerName = 'Microsoft Dynamics NAV {0} Web Client' -f $NavVersion.Version
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

        # Every working NAV Web Server is converted to an application. Retreiving all web applications from the IIS should contain all the NAV Web Server Instances.
        # Note: The PhysicalPath can contain a shortcut to the installation folder of the Web Server.

        $IIS_WebApp = Get-WebApplication | Select-Object -Property PhysicalPath, applicationPool
        
    }
    Process
    {
        $WebServerInstances = @()
        
        foreach ($App in $IIS_WebApp) {

            if($NavVersion.ProductAbb -eq 'BC'){
                $dll = Join-Path $App.PhysicalPath 'Microsoft.Dynamics.Nav.Client.WebClient.dll'
            }
            if($NavVersion.ProductAbb -eq 'NAV'){
                $dll =  Join-Path $App.PhysicalPath '\bin\Microsoft.Dynamics.Nav.Client.WebClient.dll'
            }

            if (-not (Test-Path -Path $dll)) {
                continue
            }

            $FileVersion = (Get-Item $dll).VersionInfo.FileVersion

            <#
                Check if the found instance is from the same NAV Version.
                Example:
                    Version: 2017
                    NavVersionFolder: 100
                    Build: 10.0.20784.0
                    Compair the first two characters of the version with the first two characters of the build.
            #>

            if ($NavVersion.NavVersionFolder.substring(0,2) -ne $FileVersion.substring(0,2)) {
                continue
            }

            $obj = New-Object System.Object
            $obj | Add-Member -MemberType NoteProperty -Name "Website" -Value $WebServerName
            $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $FileVersion
            $obj | Add-Member -MemberType NoteProperty -Name "InstancePath" -Value $($App.PhysicalPath + '\')

            <#
            $webConfigFile = ((get-item $IIS_WebApp.PhysicalPath).parent.FullName + '\web.config')
            
            if (Test-Path -Path $webConfigFile) {

                $obj | Add-Member -MemberType NoteProperty -Name "ConfigurationFile" -Value $webConfigFile
            }

            #>

            $obj | Add-Member -MemberType NoteProperty -Name "ApplicationPool" -Value $App.applicationPool
            

            $WebServerInstances += $obj
            Clear-Variable obj
        }

    }

    End
    {
        return $WebServerInstances
    }
}

Export-ModuleMember -Function Get-NavWebServerInstance

