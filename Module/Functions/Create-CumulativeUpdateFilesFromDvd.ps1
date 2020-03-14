<#
.SYNOPSIS
    This cmdlet copies all the nessesary files from the Dynamics NAV DVD to create a smaller patch.

.DESCRIPTION
    This cmdlet copies all the DVD files to create a batch ready set of files..
    It skips files that are not needed in CU upgrade scenarios such as .flf files.
    This version auto detects if the Source DVD is a W1 NAV version or a localization NAV version and makes the patch accordingly. 

    This is a refactored version from:
    https://blogs.msdn.microsoft.com/nav/2018/02/19/how-to-generate-the-hotfix-directories-from-microsoft-dynamics-nav/
    https://blogs.msdn.microsoft.com/nav/2014/11/13/how-to-get-back-the-hotfix-directories-from-nav-2015-cumulative-update-1/
 
.PARAMETER DvdDirectory
    Specifies the directory where the uncompressed Cumulative Update DVD subdirectory is located.
 
.PARAMETER BatchDirectory
    Specifies the directory that should hold the result set of files, i.e., the destination directory

.EXAMPLE
    Create-CumulativeUpdateFilesFromDvd -DvdDirectory "D:\Continuous Delivery\Dynamics NAV DVD\Product DVD NAV2017 NL CU17" -BatchDirectory "D:\temp\NewCUBatchFolder"  -Verbose
#>

function Create-CumulativeUpdateFilesFromDvd
{
    [CmdletBinding()]
    
    param (
        [parameter(Mandatory=$true)]
        [string] $DvdDirectory,

        [parameter(Mandatory=$true)]
        [string] $BatchDirectory

    )
 
    Process
    {
        # Get the RTC folder from the DVD folder
        if (Test-Path (Join-Path $DvdDirectory '\RoleTailoredClient\program files\Microsoft Dynamics NAV\')){
            
            # BC14, NAV2018 and older the Windows RoleTailoredClient is still supported.
            $RTCFolder = '\RoleTailoredClient\program files\Microsoft Dynamics NAV\*'

        } elseif (Test-Path (Join-Path $DvdDirectory 'LegacyDlls\program files\Microsoft Dynamics NAV')){
            
            # From Business Central 15 and up the RTC is moved to the Legancy folder. 
            $RTCFolder = 'LegacyDlls\program files\Microsoft Dynamics NAV\*'
        } else {
            
            Write-Warning "Please check your DvdDirectory parameter"
            return 
        }


        # Get NAV version from NAV DVD
        $NavVersionFolder = Split-Path -Path $(Join-Path -Path $DvdDirectory -ChildPath $RTCFolder) -Leaf -Resolve

        if (-not $NavVersionFolder) {
        
            Write-Warning "Please check your DvdDirectory parameter"
            return 
        }

        # Check if the DVD is a W1 or a language specific DVD

        $W1 = $true

        if ( Test-Path (Join-Path -Path $DvdDirectory -ChildPath "Installers") ) {
            
            $W1 = $false
        }

        # Get language code from NAV DVD

        if ($W1 -eq $false) {
            
            $LanguageFolder = Join-Path -Path $DvdDirectory -ChildPath "\Installers\"
            $LocalizedVersions = $(Get-ChildItem $LanguageFolder -Directory).Name
        }

        # Preparing move action from 
        "Preparing moving files from '{0}' to '{1}'..." -f $DvdDirectory, $BatchDirectory | Write-Verbose

        $ToMove = @()

        if ([int] $($NavVersionFolder) -ge 150) {
            $ToMove += @( @{
                        Source = "LegacyDlls\program files\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client"; 
                        Destination = "RTC";} )
        } else {
            $ToMove += @( @{
                        Source = "RoleTailoredClient\program files\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client"; 
                        Destination = "RTC";} )
        }
        $ToMove += @( @{
                        Source = "ServiceTier\program files\Microsoft Dynamics NAV\$NavVersionFolder\Service"; 
                        Destination = "NST";} )

        $ToMove += @( @{
                        Source = "WebClient\Microsoft Dynamics NAV\$NavVersionFolder\Web Client"; 
                        Destination = "WEB CLIENT";} )

        $ToMove += @( @{
                        Source = "Outlook\program files\Microsoft Dynamics NAV\$NavVersionFolder\OutlookAddin"; 
                        Destination = "OUTLOOK";} )

        $ToMove += @( @{
                        Source = "ADCS\program files\Microsoft Dynamics NAV\$NavVersionFolder\Automated Data Capture System"; 
                        Destination = "ADCS";} )

        $ToMove += @( @{
                        Source = "HelpServer\DynamicsNAV$($NavVersionFolder)Help"; 
                        Destination = "HelpServer";} )

        if ([int] $($NavVersionFolder) -ge 110 -and [int] $($NavVersionFolder) -lt 130) {
            $ToMove += @( @{
                        Source = "ModernDev\program files\Microsoft Dynamics NAV\$($NavVersionFolder)\Modern Development Environment"; 
                        Destination = "ModernDev";} )
        } elseif ([int] $($NavVersionFolder) -ge 130) {
            $ToMove += @( @{
                        Source = "ModernDev\program files\Microsoft Dynamics NAV\$($NavVersionFolder)\AL Development Environment"; 
                        Destination = "ModernDev";} )
        }

        if ([int] $($NavVersionFolder) -lt 150) {
        $ToMove += @( @{
                        Source = "UpgradeToolKit"; 
                        Destination = "UpgradeToolKit";} )
        }

        $ToMove += @( @{
                        Source = "WindowsPowerShellScripts"; 
                        Destination = "WindowsPowerShellScripts";} )

        if ([int] $($NavVersionFolder) -ge 90) {
            $ToMove += @( @{
                        Source = "CrmCustomization"; 
                        Destination = "CrmCustomization";} )
        }
        if ([int] $($NavVersionFolder) -ge 90 -and [int] $($NavVersionFolder) -lt 150) {
            $ToMove += @( @{
                        Source = "TestToolKit"; 
                        Destination = "TestToolKit";} )
        }

        if ([int] $($NavVersionFolder) -lt 110) {
            $ToMove += @( @{
                        Source = "BPA"; 
                        Destination = "BPA";} )
        }

        # Language specific folders

        if ($W1 -eq $false) {

            foreach ($LocalizedVersion in $LocalizedVersions) {

                "Preparing moving localization files for localization: {0}" -f $LocalizedVersion | Write-Verbose
                
                $ToMove += @( @{
                                Source = "Installers\$LocalizedVersion\RTC\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client"; 
                                Destination = "RTC";} )

                if ([int] $($NavVersionFolder) -lt 110) {
                
                    $ToMove += @( @{
                                    Source = "Installers\$LocalizedVersion\Server\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\Service"; 
                                    Destination = "NST";} )

                    $ToMove += @( @{
                                    Source = "Installers\$LocalizedVersion\OlAddin\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\OutlookAddIn"; 
                                    Destination = "OUTLOOK";} )

                    $ToMove += @( @{
                                    Source = "Installers\$LocalizedVersion\WebClient\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\Web Client"; 
                                    Destination = "WEB CLIENT";} )
                }
            }
        }

        # Setup language files (the folders with 4 numbers)

        $Setupfolder = Get-ChildItem -Path $DvdDirectory | Where-Object { $_.Name -match "^[0-9]{4}$" }

        foreach ($Folder in $Setupfolder) {
            
            $ToMove += @( @{
                            Source = $($Folder.Name); 
                            Destination = "SETUP\$($Folder.Name)";} )
        }

        "Done preparing the move action." | Write-Verbose
        
        # Move files from DVD to temporarly folder
        
        "Copying files from {0} to {1}..." -f $DvdDirectory, $BatchDirectory | Write-Verbose

        foreach ($Item in $ToMove) {
            
            $Source = $(Join-Path -Path $DvdDirectory -ChildPath $(Join-Path -Path $($Item.Source) -ChildPath "*"))
            $Destination = $(Join-Path -Path $BatchDirectory -ChildPath $Item.Destination)

            if(-not $(Test-Path -Path $Destination)) {
                
                New-Item -ItemType Directory -Force -Path $Destination
            }
    
            Copy-Item $Source -destination $Destination -recurse -Force
        }  

        "Done copying files from {0} to {1}." -f $DvdDirectory, $BatchDirectory | Write-Verbose
 
        "Deleting files from {0} that are not needed for the batch directory..." -f $BatchDirectory | Write-Verbose

        $FileExtensionsToDelete = @("*.chm", "*.hh", "*.config", "*.ico", "*.flf", "*.sln", "*.rtf", "*.json")
        
        $ExcludeItemsForDelete = @(
            'finsql.exe.config', 
            'Microsoft.Dynamics.Nav.Server.exe.config',
            'Microsoft.Dynamics.Nav.Client.exe.config'
        )

        Get-ChildItem $BatchDirectory -include $FileExtensionsToDelete -Recurse | Where-Object -Property Name -notin $ExcludeItemsForDelete | Remove-Item -force -ErrorAction SilentlyContinue
            
        # Delete folders that are not needed for a CU upgrade installation scenario

        $FoldersToDelete = @(
            'RTC\Images', 
            'RTC\SLT', 
            'RTC\ReportLayout', 
            'BPA\Scripts', 
            'HelpServer\css', 
            'HelpServer\help', 
            'HelpServer\images', 
            'WEB CLIENT\Resources', 
            'WindowsPowerShellScripts\ApplicationMergeUtilities')

        Foreach ($Folder in $FoldersToDelete) {
    
            Remove-Item $(Join-Path -Path $BatchDirectory -ChildPath $Folder) -force -Recurse -ErrorAction SilentlyContinue
        }

        "Done deleting files from {0} that are not needed for for the batch directory." -f $BatchDirectory | Write-Verbose

        # Specific files to add after cleanup
        
        $Source = $(Join-Path $DvdDirectory -ChildPath "setup.exe")
        $Destination = $(Join-Path -Path $BatchDirectory -ChildPath "SETUP")

        Copy-Item $Source -Destination $Destination

        $Source = $(Join-Path $DvdDirectory -ChildPath "\ServiceTier\program files\Microsoft Dynamics NAV\$NavVersionFolder\Service\CustomSettings.config")
        $Destination = $(Join-Path -Path $BatchDirectory -ChildPath "Config")
        
        if(-not $(Test-Path -Path $Destination)) {

            New-Item -ItemType Directory -Force -Path $Destination
        }

        Copy-Item $Source -Destination $Destination  
    }
}

Export-ModuleMember -Function Create-CumulativeUpdateFilesFromDvd
