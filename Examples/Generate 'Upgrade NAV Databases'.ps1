<#
    This script checks which databases must be upgraded and creates a PowerShell script to run the upgrade process per database.
    
    The list of 10.00 Navision Services (NST's) is used to create [UpgradeMyDatabases.ps1] in the scriptroot folder.
#>

# ************************************************************* [Script] ********************************************************************* #

# Load Deployment Settings 

    $ScriptRootPath = $PSScriptRoot
    . "$ScriptRootPath\Load Deployment Settings.ps1"

# Write Log
    
    $Message = "Generating [UpgradeMyDatabases.ps1]..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Get the pre-filled cmdlets to convert the databases and write it to file

    $ToConvertDatabases = Convert-NavDatabases -NavVersion $NavVersion

    if (Test-Path $ConvertMyDatabasesScript) { 
        Remove-Item $ConvertMyDatabasesScript -force
    } 
 
    Add-Content $ToConvertDatabases -path $ConvertMyDatabasesScript

# Write Log
    
    $Message = "`n $ConvertMyDatabasesScript created.`n"
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Open Upgrade NAV Databases in a new ISE tab
    
    $Message = "Opening {0} in a new tab..." -f $(Split-Path $ConvertMyDatabasesScript -Leaf)
    Write-Log -Path $LogPath -Message  $Message -Level Info

    $psISE.CurrentPowerShellTab.Files.Add($ConvertMyDatabasesScript) | Out-Null