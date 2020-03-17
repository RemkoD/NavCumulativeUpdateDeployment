<#
    This script will install the Microsoft Dynamics NAV Platform Cumulative Update.

    The installation flow:
        
        1. Initialisation
            - Active logging
            - Check if script is executed as admin
            - Check if powershell version is supported
            - Validate deployment settings

        2. Scan environment
            - Scans Windows Registery on installed NAV Components
            - Scans system on installed Help instances
            - Scans system on installed webclients

        3. Validate build version
            - Checks if the to-deploy cumulative update is newer than the current NAV version

        4. Stop blocking processes
            - Stops blocking processes (NAV Service Tiers)
            - Stops blocking services (NAV client, MS Office, ..)
            - Stops blocking Applicationpools 

        5. Check files are writeable
            - Check all the to-update files if they are writeable (not locked by other processes)

        6. Create backup
            - Makes a backup of the files from each installed NAV component that is going to be updated with the new CU

        7. Installation Cumulative Update
            - Each NAV Component is updated with the new cumulative update files

        8. Update Config Files
            - The Dynamics NAV Service default CustomSettings.config is updated with (optional) new available configuration keys

        9. Update Windows Registery
            - Register the new Cumulative Update Version (Build number) in the Windows Registery for each updated NAV Component 

        10. Write Summary
            - Shows which components are updated

        The Cumulative Update Installation is completed. Now the NAV databases can be converted to the new platform.

#>

# ************************************************************* [Script] ********************************************************************* #

#region Initialisation 

# Check if the AppLocker policy is disabled. LanguageMode should be FullLanguage.

    if ( $($ExecutionContext.SessionState.LanguageMode) -ne 'FullLanguage') {

        $Message = "Script cannot be executed. Current LanguageMode is {0}, this chould be FullLanguage." -f `
                    $($ExecutionContext.SessionState.LanguageMode)
        
        $Message += "Make sure that the AppLocker policy is disabled."

        Write-Host $Message

    }

# Load Deployment Settings 

    $ScriptRootPath = $PSScriptRoot
    . "$ScriptRootPath\Load Deployment Settings.ps1"

# Check if Powershell engine 3.0 is pressent
    
    if (-not $PSVersionTable.PSVersion.Major -ge '3') {

        $Message = "Powershell 3.0 or higher required to continue. Current version is {0}.{1}" -f `
                    $($PSVersionTable.PSVersion.Major), `
                    $($PSVersionTable.PSVersion.Minor)

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    }

# Unblock files that are blocked 
    
    Get-ChildItem -Path $ScriptRootPath -File -Recurse | ForEach { Get-Item -Path $_.FullName } | ForEach { Unblock-File $_.FullName }

# Start Logging
    
    $Message = "Starting Dynamics NAV Cumulative Update deployment..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Log PowerShell Version
    
    $Message = "Powershell Version: {0}.{1} is used" -f `
                $($PSVersionTable.PSVersion.Major), `
                $($PSVersionTable.PSVersion.Minor)

    Write-Log -Path $LogPath -Message  $Message -Level Info

# Check if script is executed as admin

    $WindowsIdentity = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
    $elevated = ($WindowsIdentity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    
    if (-not ($elevated)) {

        $Message = "You need administrative privileges to deploy a cumulative update. Start the script as an administrator."
        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    } 

    $Message = "Script is executed with administrator privileges."
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Check if script is executed in a 64 bit process. 
# If executed as 32bit the script cannot read the x64 reg keys. Resulting in not updating the x64 components.
    if(-not [Environment]::Is64BitProcess){
        $Message = "This script needs to be executed as a 64 bit process. Current process is x86 (32bit)."
        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    }

# Check if supplied NAV version is valid
    
    if (-not (Get-NavVersionFolder -NavVersion $NavVersion)) {
        
        $Message = "'$NavVersion' is not recognized as valid NAV release. "
        $Message += "Example valid NAV releases are: '2013 R2', '2015', '2017' or '2018'. "
        $Message += "Check the input variable and check if there is a newer version of this script available. "
        
        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    } 

    $Message = "Targeted NAV release: $NavVersion"
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Test if set Cumulative Update Location exists

    if(!(test-path $CumulativeUpdateLocation)){
          
        $Message = "Cumulative Update location not found: $CumulativeUpdateLocation"
        Write-Log -Path $LogPath -Message  $Message -Level Warn
          
        if ($UserValidation) {

            Show-MessageBox `
                    -Message $Message `
                    -Icon "Error" `
                    -ErrorMsg $Message `
                    -Throw `
                    -MessageType $MessageType `
                    -Button 'OK'
        }

        throw $Message
    }

# Get the to-install CU folder
    
    if ($CUFolder) { Clear-Variable CUFolder }

    $Folders = Get-ChildItem -Path $CumulativeUpdateLocation -Directory
    
    foreach ($Folder in $Folders) {
        
        if ($Folder.Name -like "*$NavVersion*" -and $Folder.Name -like "*$CumulativeUpdate*" -and $Folder.Name -like "*$Localisation*") {
            
            $Message = "The to-install Cumulative Update folder found: $Folder `n"
            Write-Log -Path $LogPath -Message  $Message -Level Info

            $CUFolder = $Folder

            break
        }
    }

    if (-not $CUFolder) {

        $Message  = "The to-install Cumulative Update folder is not found. `n`n"
        $Message += "Check the build nummer in the variable `$CumulativeUpdate is set with a valid value and if the files are pressent in the Cumulative Update folder '{0}'. `n`n" -f `
                     $CumulativeUpdateLocation
        $Message += "The Cumulative Update folder should contain the NAV release, NAV build number and NAV localisation (2 characters), example: NAV2017_NL_CU19_Build_10.0.22286.0"
        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation) {

            Show-MessageBox `
                    -Message $Message `
                    -Icon "Error" `
                    -ErrorMsg $Message `
                    -Throw `
                    -MessageType $MessageType `
                    -Button 'OK'
        }

        throw $Message
    }

#endregion

#region ScanEnvironmentForNavComponents

# Get all installed NAV components on the local host

    $NavComponent = Get-NavComponent -NavVersion $NavVersion
    #$NavComponent | Export-CliXML $($LogPath + 'NavComponents.xml' )

    if (($NavComponent | Where-Object IsInstalled -eq $True).Count -eq 0) {
        
        $Message = "Dynamics NAV $NavVersion is not installed on this machine."
        Write-Log -Path $LogPath -Message  $Message -Level Warn
        
        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    }

    $Message = "Found NAV components: {0}" -f
        $($NavComponent | Where IsInstalled -eq $true | Select-Object DisplayName, InstallLocation, DisplayVersion | Format-List | Out-String)

    Write-Log -Path $LogPath -Message  $Message -Level Info

# Get all installed NAV help instances on the local host
    
    if ($(($NavComponent | Where-Object Component -eq 'HelpServer').IsInstalled) -eq $true) {

        $HelpInstance = Get-NavHelpInstance -NavVersion $NavVersion
        $Message = "Found Help Instances: $($HelpInstance | Format-List | Out-String)"
        Write-Log -Path $LogPath -Message  $Message -Level Info
    }

# Get all installed NAV web client instances on the local host
    
    if ($(($NavComponent | Where-Object Component -eq 'WEB CLIENT').IsInstalled) -eq $true) {

        $WebServerInstance = Get-NavWebServerInstance -NavVersion $NavVersion
        $Message = "Found NAV Webclient Instances: $($WebServerInstance | Format-List | Out-String)"
        Write-Log -Path $LogPath -Message  $Message -Level Info
    }

#endregion

#region CheckBuildVersion

    $OldBuild = $($NavComponent | Where-Object IsInstalled -eq $true | Select-Object -Property DisplayVersion -First 1).DisplayVersion

    if ($DisableVersionCheck -ne $True) {
    
        if ($([version] $CumulativeUpdate).Build -le $([version] $OldBuild).Build) {
        
            $Message = "Your current NAV version $OldBuild is newer or equal to the Cumulative Update you're trying to install: $CumulativeUpdate. `n`n"
            $Message += "This installation is canceled. You can disable the version validation by setting `$DisableVersionCheck to `$true."

            Write-Log -Path $LogPath -Message  $Message -Level Warn

            if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
                Show-MessageBox `
                    -Message $Message `
                    -Icon "Error" `
                    -MessageType $MessageType `
                    -Button 'OK'
            }

            throw $Message
        }
    }

#endregion

#region StopBlockingProcessesAndServices

# Stop blocking processes and applicationpools
    
    if ($UserValidation) {

        $Mode = 'stopconfirm'
    } else {

        $Mode = 'stopsilent'
    }

    # Only include parameter WebServer to the function Stop-LocalNavEnvironment if the component is pressent on the machine.

    $StopWebServer = $false

    if ($(($NavComponent | Where-Object Component -eq 'HelpServer').IsInstalled) -eq $true) {

        $StopWebServer = $true
    }

    if ($(($NavComponent | Where-Object Component -eq 'WEB CLIENT').IsInstalled) -eq $true) {

        $StopWebServer = $true
    }
        
    Stop-LocalNavEnvironment `
                  -Mode $Mode `
                  -NavVersion $NavVersion `
                  -MSOffice `
                  -NAVClient `
                  -NAVService `
                  -WebServer:$StopWebServer `
                  -Throw
#endregion

#region ValidateFilesAreEditable

# Test if all the NAV files are free from locks
    
    $Message = "Testing NAV components on file locks..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

    $PathsToCheck = $(($NavComponent | Where IsInstalled -eq $true | Where Component -ne 'HelpServer').InstallLocation)
    
    if($HelpInstance) {

        $PathsToCheck += $(($HelpInstance | Select InstancePath).InstancePath)
    }

    $LockedFiles = Test-FilesLock -Path $PathsToCheck

    if ($LockedFiles) {
        
        $Message = "Some files are still locked, cumulative update installation is aborted. "
        $Message += "The following files are still locked: "
        $Message += $($LockedFiles | Out-String)
        $Message += "With the Sysinternal tools Process Explorer and Handle.exe the blocking processes can be found. "
        $Message += "Or try to rerun Stop-LocalNavEnvironment."

        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $message
    }

    $Message = "All NAV files are in an unlocked state"
    Write-Log -Path $LogPath -Message  $Message -Level Info

#endregion

#region CreateBackup

# Create a backup

    $Message = "Backing up current NAV component files..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # Check free diskspace

    if (-not (Split-Path -Path $BackupFolderPath -IsAbsolute)) {
        
        $Message = "Backup path should be an absolue path on the local system that is going to be upgraded."
        $Message = "For example: C:\Temp\NAVBackup or D:\Temp\NAVBackup"
        
        Write-Log -Path $LogPath -Message  $Message -Level Error

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    }

    $BackupDrive = Get-PSDrive -Name $($BackupFolderPath.Substring(0,1))
    $BackupDiskFreeSpace = $($BackupDrive.Free /1MB)       

    #$ScriptDisk = ((Get-Item $ScriptRootPath).PSDrive.Free /1MB)
    
    if ($BackupDiskFreeSpace -lt 800) {

        $Message = "Currently less then 800 Megabytes free space is available on drive {0}" -f `
            $BackupDrive.Root

        $Message += "Make sure more then 800 Megabytes is available for creating a backup."

        Write-Log -Path $LogPath -Message  $Message -Level Warn

        if ($UserValidation -eq $true -and $MessageType -eq 'MessageBox') {
            Show-MessageBox `
                -Message $Message `
                -Icon "Error" `
                -MessageType $MessageType `
                -Button 'OK'
        }

        throw $Message
    }

    $Message = "There is enough free space available on disk {0} for creating a backup. Total free space: {1} GB" -f `
            $BackupDrive.Root, `
            [math]::Round(($BackupDrive.Free /1GB),2)
    
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # Example backup folder name: NAV2017_2018-04-30_Build_10.0.15140.0

    $BackupFolder = "NAV{0}_{1}_Build_{2}" -f `
        $NavVersion, `
        $(Get-Date -UFormat "%Y-%m-%d"), `
        $(($NavComponent | Where-Object IsInstalled -eq $true | Select-Object -Property DisplayVersion -First 1).DisplayVersion)

    $BackupFolder = Join-Path -Path $BackupFolderPath -ChildPath $BackupFolder

    # Create backup folder if not exists

    If(!(test-path $BackupFolder)){
          
          New-Item -ItemType Directory -Force -Path $BackupFolder | Out-Null
          
          $Message = "Backup folder created: $BackupFolder"
          Write-Log -Path $LogPath -Message  $Message -Level Info
    }

    # Make a backup from each componentpath

    foreach ($Component in $($NavComponent | Where-Object IsInstalled -eq $true)) {
        
        if ($Component.Component -eq 'HelpServer') {
            
            foreach ($Instance in $HelpInstance) {
                    
                $Message = "Making a backup from {0}`n  source {1} `n  destination {2}`n" -f `
                            $($Component.Displayname), `
                            $($Instance.InstancePath), `
                            $(Join-Path -Path $BackupFolder -ChildPath $Component.Component)
                
                Write-Log -Path $LogPath -Message  $Message -Level Info

                Copy-Item -Path $($Instance.InstancePath) -Destination $(Join-Path -Path $BackupFolder -ChildPath $Component.Component) –Recurse -Force -errorAction stop
            }
            
            continue
        }
        
        $Message = "Making a backup from {0}`n  source {1} `n  destination {2}`n" -f `
                            $($Component.Displayname), `
                            $($Component.InstallLocation), `
                            $(Join-Path -Path $BackupFolder -ChildPath $Component.Component)

        Write-Log -Path $LogPath -Message  $Message -Level Info

        Copy-Item -Path $($Component.InstallLocation) -Destination $(Join-Path -Path $BackupFolder -ChildPath $Component.Component) –Recurse -Force

    }

#endregion

#region UpdateNAVComponents

# Update NAV Components

    $Message = "All validations passed successfully!"
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # User confirmation to start the CU deployment

    if ($UserValidation) {

        Show-MessageBox `
                -Message "All validations passed successfully, do you want to upgrade the NAV components?" `
                -Icon "Question" `
                -ErrorMsg "Upgrading aborted by users choice" `
                -Throw `
                -MessageType $MessageType `
                -Button 'YesNoCancel'
    }

    $Message = "Upgrading the NAV components with the Cumulative Update..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # Update each installed component with the files from the to-install CU folder

    foreach ($Component in $($NavComponent | Where-Object IsInstalled -eq $true)) {
        
        $CUComponentPath = Join-Path -Path $CumulativeUpdateLocation -ChildPath (Join-Path -Path $CUFolder -ChildPath $($Component.Component))
        
        if ($Component.Component -eq 'HelpServer') {
            
            foreach ($Instance in $HelpInstance) {

                $Message = "Updating {0}`n  from source {1} `n  to destination {2} `n" -f `
                            $($Component.Displayname), `
                            $CUComponentPath, `
                            $($Instance.InstancePath)
                
                Write-Log -Path $LogPath -Message  $Message -Level Info

                Copy-Item -Path $(Join-Path -Path $CUComponentPath -ChildPath "*") -Destination $($Instance.InstancePath) –Recurse -Force -ErrorAction stop
                
            }
            
            Clear-Variable CUComponentPath
            continue

        }

        # NAV2018 and lower: The NAV website in IIS contains a shortcut to the program files web client folder.
        # Business Central: The BC website in IIS contains all the binairy files.
        if  ($Component.Component -eq 'WEB CLIENT' -and
            (Get-NavVersionFolder -NavVersion $NavVersion).ProductAbb -eq 'BC') 
        {
            foreach ($Instance in $WebServerInstance) {
                $WebPublishPath = Join-Path $CUComponentPath 'WebPublish'

                $Message = "Updating {0}`n  from source {1} `n  to destination {2} `n" -f `
                            $($Component.Displayname), `
                            $WebPublishPath, `
                            $($Instance.InstancePath)
                
                Write-Log -Path $LogPath -Message  $Message -Level Info

                Copy-Item -Path $(Join-Path -Path $WebPublishPath -ChildPath "*") -Destination $($Instance.InstancePath) –Recurse -Force -ErrorAction stop
                
            }
            
            # No continue here. Both the webclients in IIS and in programfiles needs to be updated.
        }   
        $Message = "Updating {0}`n  from source {1} `n  to destination {2} `n" -f `
                    $($Component.Displayname), `
                    $CUComponentPath, `
                    $($Component.InstallLocation)

        Write-Log -Path $LogPath -Message  $Message -Level Info

        Copy-Item -Path $(Join-Path -Path $CUComponentPath -ChildPath "*") -Destination $($Component.InstallLocation) –Recurse -Force -ErrorAction stop

        Clear-Variable CUComponentPath
    }

    # Update NAV setup files
    $CUComponentPath = $(Join-Path -Path $CumulativeUpdateLocation -ChildPath (Join-Path -Path $CUFolder -ChildPath "SETUP\*"))
    $Destination = $(Join-Path ${env:CommonProgramFiles(x86)} -ChildPath "Microsoft Dynamics NAV\$((Get-NavVersionFolder -NavVersion $NavVersion).NavVersionFolder)\Setup")

    $Message = "Updating NAV Setup files `n  from source {0} `n  to destination {1} `n" -f `
                    $CUComponentPath, `
                    $Destination
    
    Write-Log -Path $LogPath -Message  $Message -Level Info

    Copy-Item -Path $CUComponentPath -Destination $Destination -Recurse -Force -ErrorAction stop

#endregion

#region UpdateConfigFiles

    $Message = "Updating configuration files..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

# Update the default CustomSettings.config for the default NAV Service Tier (NST)

    if ($(($NavComponent | Where-Object Component -eq 'NST').IsInstalled) -eq $true) {
        
        $DefaultConfigNewPath = Join-Path -Path $CumulativeUpdateLocation -ChildPath $(Join-Path -Path $CUFolder -ChildPath 'Config\CustomSettings.config')
        $DefaultConfigCurrentPath = Join-Path -Path $(($NavComponent | Where-Object Component -eq 'NST').InstallLocation) -ChildPath "CustomSettings.config"

        [xml]$DefaultConfigNew = Get-Content $DefaultConfigNewPath
        [xml]$DefaultConfigCurrent = Get-Content $DefaultConfigCurrentPath

        # Check if new keys became available or keys became depricated in the new CU

        $NewKeys = Compare-Object -ReferenceObject $($DefaultConfigNew.appSettings.add.key) -DifferenceObject $($DefaultConfigCurrent.appSettings.add.key) | Where{$_.SideIndicator -eq '<='} | Select * -Exclude SideIndicator
        #$DeprecatedKeys = Compare-Object -ReferenceObject $($DefaultConfigNew.appSettings.add.key) -DifferenceObject $($DefaultConfigCurrent.appSettings.add.key) | Where{$_.SideIndicator -eq '=>'} | Select * -Exclude SideIndicator

        # If there are new keys, add them to the default CustomSettings.config

        if ($NewKeys.Count -ge 1) {

            foreach( $Key in $NewKeys.InputObject ) {
        
                # Get the default value for the new key

                $NewKey = $($DefaultConfigNew.appSettings.add | Where -Property key -eq $Key)
        
                # Add the new key with default value to the current default config file
        
                $newAppSetting = $DefaultConfigCurrent.CreateElement("add")
                $DefaultConfigCurrent.appSettings.AppendChild($newAppSetting) | Out-Null
        
                $newAppSetting.SetAttribute("key",$($NewKey.key));
                $newAppSetting.SetAttribute("value",$($NewKey.value));
        
                $DefaultConfigCurrent.Save($DefaultConfigCurrentPath)

                $Message  = "The following key is added to NST Service default CustomSettings.config: "
                $Message += $($NewKey | Out-String)
                Write-Log -Path $LogPath -Message $Message -Level Info
            }

        } else {

            $Message  = "There are no new keys available for the NST Service default CustomSettings.config"
            Write-Log -Path $LogPath -Message $Message -Level Info
        }

    } # End if

    $Message = "Updating configuration files completed"
    Write-Log -Path $LogPath -Message  $Message -Level Info

#endregion

#region UpdateWindowsRegistery

# Update Windows Reg

    $Message = "Updating Windows registry..."
    Write-Log -Path $LogPath -Message  $Message -Level Info

    Update-WinRegNavBuild -OldBuild $OldBuild -NewBuild $CumulativeUpdate

    $Message = "Updating Windows registry completed."
    Write-Log -Path $LogPath -Message  $Message -Level Info

#endregion

#region WriteSummery

# Show summery
    $Message = "Microsoft Dynamics NAV platform cumulative update installation is completed! `n`n"
    $Message += "The following Microsoft Dynamics NAV $NavVersion components are upgraded from $OldBuild to $CumulativeUpdate`: `n`n"
    $Message += $($NavComponent | Where-Object IsInstalled -eq $true | Select-Object -Property DisplayName).DisplayName | Out-String

    Write-Log -Path $LogPath -Message  $Message -Level Info

    if ($UserValidation) {

        Show-MessageBox `
                -Message $Message `
                -Icon "Information" `
                -MessageType $MessageType `
                -Button 'Ok'
    }

#endregion