<#
.Synopsis
    Either returns the Microsoft.Dynamics.Nav.Model.Tools module path or imports the module. 

.DESCRIPTION
    Returns the module path if -Import is $false and the module is found
    Returns $false if module is not found
    Returns $false if switch -Import is $true and module is not loaded after import-module
    Returns $true if switch -Import is $true and and module is loaded succesfully 

.EXAMPLE
    # Receive the module path for NAV module Microsoft.Dynamics.Nav.Model.Tools
    Get-NavModelToolsModule -NavVersion 2017

.EXAMPLE
    # Imports the Microsoft.Dynamics.Nav.Model.Tools.psm1 module and returns $true
    Get-NavModelToolsModule -NavVersion 2017 -Import
	
.PARAMETER NavVersion
	# The installed NAV Version where you want to import the module from. For example: NAV2016, NAV2017 or NAV2018
	
.PARAMETER Import
	# Switch to $true to import the module. When left on $false this functions returns the module path.
#>

function Get-NavManagementModule
{

    Param
    (     
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        
        [string] $NavVersion,
        
        [Parameter(Mandatory=$false,
                   Position=1)]
        
        [switch] $Import = $false
    )

    Process
    {
        $ModuleName = 'Microsoft.Dynamics.Nav.Management'

        $NavService = Get-NavComponent -NavVersion $NavVersion | Where-Object Component -eq 'NST'

        if (-not $NavService.IsInstalled) {
            
            return $false
        }

        $ModulePath = Join-Path -Path $NavService.InstallLocation -ChildPath $($ModuleName + ".psd1")

        if (-not (Test-Path -Path $ModulePath)) {

            return $false
        }

        if ($Import) {
            
            Import-Module $ModulePath -DisableNameChecking -Global -Force

            if (-not (Get-Module -Name $ModuleName)) {
                
                return $false
            }

            return $true
        }

        return $ModulePath
        
    }
}

Export-ModuleMember -Function Get-NavManagementModule