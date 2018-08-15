<#
.SYNOPSIS
    This cmdlet copies all the nessesary files from the Dynamics NAV DVD to create a smaller patch.

.DESCRIPTION
    This cmdlet copies all the DVD files to create a batch ready set of files..
    It skips files that are not needed in CU upgrade scenarios such as .flf files.
    This version auto detects if the Source DVD is a W1 NAV version or a localization NAV version and makes the patch accordingly. 

    This is a refactored version from:
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

        # Get NAV version from NAV DVD
        
        $RTCFolder = "\RoleTailoredClient\program files\Microsoft Dynamics NAV\*"
        $NavVersionFolder = Split-Path -Path $(Join-Path -Path $DvdDirectory -ChildPath $RTCFolder) -Leaf -Resolve
        
        if (-not $NavVersionFolder) {
        
            Write-Host "Please check your DvdDirectory parameter"
            return 
        }

        # Check if the DVD is a W1 or a language specific DVD

        $W1 = $true

        if ( Test-Path (Join-Path -Path $DvdDirectory -ChildPath "Installers") ) {
            
            $W1 = $false
        }

        # Get language code from NAV DVD

        if ($W1 -eq $false) {

            $RTCLanguageFolder = Resolve-Path $(Join-Path -Path $DvdDirectory -ChildPath "Installers\*\RTC\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client")
            $LanguageCode = $(Get-ChildItem -Path $RTCLanguageFolder -Directory | foreach -Process {if ($_.Name.Length -eq 5) {$_}}).Name
            $Culture = New-Object System.Globalization.CultureInfo($LanguageCode) -ErrorAction Stop
        
            $LanguageCode = $Culture.Name
            $LanguageThreeLetter = $Culture.ThreeLetterWindowsLanguageName
            $LanguageTwoLetter = $Culture.TwoLetterISOLanguageName
        }

        # Move files from DVD to temporarly folder

        Write-Verbose "Copying files from $DvdDirectory to $BatchDirectory..."

        $ToMove = @()

        $ToMove += @( @{
                        Source = "RoleTailoredClient\program files\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client"; 
                        Destination = "RTC";} )

        $ToMove += @( @{
                        Source = "ServiceTier\program files\Microsoft Dynamics NAV\$NavVersionFolder\Service"; 
                        Destination = "NST";} )

        $ToMove += @( @{
                        Source = "BPA"; 
                        Destination = "BPA";} )

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

        $ToMove += @( @{
                        Source = "UpgradeToolKit"; 
                        Destination = "UpgradeToolKit";} )

        $ToMove += @( @{
                        Source = "WindowsPowerShellScripts"; 
                        Destination = "WindowsPowerShellScripts";} )

        # NAV version specific folders

        if ([int] $($NavVersionFolder) -ge 90) {

            $ToMove += @( @{
                        Source = "CrmCustomization"; 
                        Destination = "CrmCustomization";} )

            $ToMove += @( @{
                        Source = "TestToolKit"; 
                        Destination = "TestToolKit";} )
        }

        # Language specific folders

        if ($W1 -eq $false) {

            $ToMove += @( @{
                            Source = ”Installers\$LanguageTwoLetter\RTC\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\RoleTailored Client”; 
                            Destination = "RTC";} )

            $ToMove += @( @{
                            Source = ”Installers\$LanguageTwoLetter\Server\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\Service”; 
                            Destination = "NST";} )

            $ToMove += @( @{
                            Source = ”Installers\$LanguageTwoLetter\OlAddin\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\OutlookAddIn”; 
                            Destination = "OUTLOOK";} )

            $ToMove += @( @{
                            Source = ”Installers\$LanguageTwoLetter\WebClient\PFiles\Microsoft Dynamics NAV\$NavVersionFolder\Web Client\bin”; 
                            Destination = "WEB CLIENT";} )
        }

        # Setup language files (the folders with 4 numbers)

        $DvdDirectory = "D:\Continuous Delivery\Cumulative Update\Files\Product DVD NAV2017 NL CU19"
        $Setupfolder = Get-ChildItem -Path $DvdDirectory | Where-Object { $_.Name -match "[0-9]{4}" }

        foreach ($Folder in $Setupfolder) {
            
            $ToMove += @( @{
                            Source = $($Folder.Name); 
                            Destination = "SETUP\$($Folder.Name)";} )
        }

        foreach ($Item in $ToMove) {
            
            $Source = $(Join-Path -Path $DvdDirectory -ChildPath $(Join-Path -Path $($Item.Source) -ChildPath "*"))
            $Destination = $(Join-Path -Path $BatchDirectory -ChildPath $Item.Destination)

            if(-not $(Test-Path -Path $Destination)) {
                
                New-Item -ItemType Directory -Force -Path $Destination
            }
    
            Copy-Item $Source -destination $Destination -recurse -Force
        }  

        Write-Verbose "Done copying files from $DvdDirectory to $BatchDirectory."
 
        # Delete files that are not needed for a CU upgrade installation scenario

        Write-Verbose "Deleting files from $BatchDirectory that are not needed for the batch directory..."

        $FileExtensionsToDelete = @("*.chm", "*.hh", "*.config", "*.ico", "*.flf", "*.sln", "*.rtf")
            
        Get-ChildItem $BatchDirectory -include $FileExtensionsToDelete -Recurse | Remove-Item -force -ErrorAction SilentlyContinue

        # Delete folders that are not needed for a CU upgrade installation scenario

        $FoldersToDelete = @('RTC\Images', 'RTC\SLT', 'RTC\ReportLayout', 'BPA\Scripts', 'HelpServer\css', 'HelpServer\help', 'HelpServer\images', 'WindowsPowerShellScripts\ApplicationMergeUtilities')

        Foreach ($Folder in $FoldersToDelete) {
    
            Remove-Item $(Join-Path -Path $BatchDirectory -ChildPath $Folder) -force -Recurse -ErrorAction SilentlyContinue
        }

        Write-Verbose "Done deleting files from $BatchDirectory that are not needed for for the batch directory."

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