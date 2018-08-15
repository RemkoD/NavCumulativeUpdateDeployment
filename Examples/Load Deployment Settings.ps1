# ********************************************** [Script Parameters] ********************************************** #

# Set the NAV Release to patch with the cumulative platform update. 
# Example: 'NAV2017'
    
    $NavVersion = ''

# Set the cumulative update build number you want to upgrade to. 
# Example: '10.0.21440.0'

    $CumulativeUpdate = ''

# Set localisation current NAV installation. 
# Example: 'NL' or 'W1'

    $Localisation = '' 

# Set script root location

    $ScriptRootPath = $PSScriptRoot

# Set file name for Upgrade My Databases script

    $ConvertMyDatabasesScript = Join-Path -Path $ScriptRootPath -ChildPath "Step 3 - Upgrade My Databases.ps1"

# Set Cumulative Update path
# If CU path is: \\server\share\update script\cumulative update\NAV2017_NL_CU16_Build_10.0.20784.0\ 
# Set CumulativeUpdateLocation to: $CumulativeUpdateLocation = "\\server\share\update script\cumulative update"
    
    $CumulativeUpdateLocation = Join-Path -Path $ScriptRootPath -ChildPath "Cumulative Updates"

# Set path to PowerShell Module 'NavCumulativeUpdateDeployment'

    $CUDeploymentModulePath = Join-Path -Path $ScriptRootPath -ChildPath "Module\NavCumulativeUpdateDeployment.psd1"

# Set logging location
    
    # Example: 2018-06-02_logging.txt

    $LogFile = "$(Get-Date -UFormat "%Y-%m-%d_%H%M%S")_logging.txt"
    $LogPath = Join-Path -Path "C:\Temp\Dynamics NAV CU Upgrade Logging" -ChildPath $LogFile

# Set backup location
# This script will make a backup from the NAV files before overwriting them with new files. 

    $BackupFolderPath = "C:\Temp\Backup Dynamics NAV"

# Set User Validation. $False for silent installation. $True for manually confirming crucial actions. 

    $UserValidation = $True

# Message type (if UserValidation is used). InShell or MessageBox

    $MessageType = 'MessageBox'

# Version check validates if the current installed NAV build number is older than the to-install NAV build number.
# You can disable version check by setting $DisableVersionCheck to true.

    $DisableVersionCheck = $true

# ********************************************** [Import Module] ********************************************** #

# Import NavCumulativeUpdateDeployment
    
    Import-Module $CUDeploymentModulePath -DisableNameChecking -Force