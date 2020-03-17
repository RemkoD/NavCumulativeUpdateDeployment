<#
.Synopsis
    Get the active running services, processes and applicationpools that might lock the files from the targeted NAV Version and stop them

.DESCRIPTION
    Long description

.EXAMPLE
    Stop-LocalNavEnvironment -Mode 'checkonly' -NavVersion 2016 -NAVService
    Writes to host all the NAV NST services from NAV 2016 that are currently running.

.EXAMPLE
    Stop-LocalNavEnvironment -Mode 'stopconfirm' -NavVersion 2017 -MSOffice -NAVClient -NAVService -WebServer
    Writes to host if MSOffice (Outlook, Excel and/or Word) processes are running, if NAV RTC client or NAV Services are running and if there are applicationpools active with NAV instances. 
    The user gets prompt for confirmation whereafter the script stops the listed items. 

.EXAMPLE
    Stop-LocalNavEnvironment -Mode 'stopsilent' -NavVersion 2017 -MSOffice -NAVClient -NAVService -WebServer
    'stopsilent' is usefull for deploying the script automatically.

.PARAMETER Mode
    stopsilent = stop processes silently
    stopconfirm = show processes that this cmdlet would stop and proceeds with stopping the processes after users confirmation
    checkonly = show processes that this function would stop

.PARAMETER NavVersion
    The Nav Version, example: '2017', '2018', '2013 R2'
    Only the NAV Service Tiers from the supplied Nav Version will be stopped. 

.PARAMETER MSOffice
    If this switch is true this function will mark/stop Microsoft Office service that can block NAV files from the supplied NAV version. (Outlook, Word, Excel)

.PARAMETER NAVClient
    If this switch is true this function will mark/stop NAV Windows Client services that can block NAV files from the supplied NAV version.

.PARAMETER NAVService
    If this switch is true this function will mark/stop NAV Service Tiers (NSTs) that can block NAV files from the supplied NAV version.

.PARAMETER WebServer
    Stop WebServer processes, including NAV Web Client and NAV Help Server.
    This switch will retrieve the corresponding applicationspools automatically.
    To manually supply the applicationpools use the ApplicationPool parameter instead of using this switch.

.PARAMETER Throw
    If set to true and the function is executed in mode stopconfirm and the user disagrees with stopping one of the services, processes or applicationpools: throw

#>
function Stop-LocalNavEnvironment
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([array])]
    Param
    (

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   HelpMessage="'stopsilent' to stop processes silently, 'stopconfirm' to stop processes with user confirmation, 'checkonly' to check which processes would be stopped")]
        [ValidateSet('stopsilent', 'stopconfirm', 'checkonly')]
        [string] $Mode = 'stopconfirm',

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string] $NavVersion,

        [Parameter(Mandatory=$false)]
        [switch] $MSOffice,

        [Parameter(Mandatory=$false)]
        [switch] $NAVClient,

        [Parameter(Mandatory=$false)]
        [switch] $NAVService,

        [Parameter(Mandatory=$false)]
        [switch] $WebServer,

        [Parameter(Mandatory=$false)]
        [array] $ApplicationPool,

        [Parameter(Mandatory=$false)]
        [switch] $Throw = $false
    )

    Begin
    {
        # Validate NAV Version and get NAV version
        $nr = Get-NavVersionFolder($NavVersion)
        $NavVersionFolder = $nr.NavVersionFolder
        $NavVersion = $nr.Version

    }
    Process
    {
        
        # Get the active running services, processes and applicationpools that might lock the files from the targeted NAV Version

        $ServicesToStop = Get-ServicesToStop
        $ProcessesToStop = Get-ProcessesToStop
        $AppPoolsToStop = Get-ApplicationpoolsToStop

        # Write results to host
        if ($Mode -eq 'checkonly') {
            
            # Services to stop 

            $Message = "Following services can lock Dynamics NAV $NAVVersion files and are marked to stop"
            Write-Log -Path $LogPath -Message  $Message -Level Info
            
            if ($ServicesToStop) { $Message = $($ServicesToStop | Format-List | Out-String)} else { $Message = "None" }
            Write-Log -Path $LogPath -Message  $Message -Level Info

            # Processes to stop 

            $Message = "Following processes can lock Dynamics NAV $NAVVersion files and are marked to stop"
            Write-Log -Path $LogPath -Message  $Message -Level Info

            if ($ProcessesToStop) { $Message = $($ProcessesToStop | Format-List | Out-String) } else { $Message = "None" }
            Write-Log -Path $LogPath -Message  $Message -Level Info

            # Applicationpools to stop 

            $Message =  "Following applicationpool(s) can lock Dynamics NAV $NAVVersion files and are marked to stop"
            Write-Log -Path $LogPath -Message  $Message -Level Info

            if ($AppPoolsToStop) { $Message = $($AppPoolsToStop | Format-List | Out-String) } else { $Message = "None" }
            Write-Log -Path $LogPath -Message  $Message -Level Info

            return
        }

        # Stop the marked services, processes and applicationpools

        if($Mode -eq 'stopsilent' -or $Mode -eq 'stopconfirm') {

            if ($ServicesToStop) {
                Stop-MarkedServices ($ServicesToStop)
            }

            if ($ProcessesToStop) {
                Stop-MarkedProcesses ($ProcessesToStop)
            }

            if ($AppPoolsToStop) {
                Stop-MarkedApplicationpools ($AppPoolsToStop)
            }
        
        }

    }
    End
    {


    } # End End

} # End Stop-LocalNavEnvironment

Export-ModuleMember -Function Stop-LocalNavEnvironment

function Get-ServicesToStop () {
            
    $ServicesToStop = @()

    # Microsoft Dynamics NAV Server

    if ($NAVService) {

        # Get all running NAV services
        $NavServices = get-wmiobject win32_service | Where-Object Name -like 'MicrosoftDynamicsNavServer*' | Where-Object State -eq 'Running' 

        # Get all NAV PIDs corresponding with the NAV Version
        # Compare if NavVersionFolder correspond with the FileVersion. 
        # Example: NavVersionFolder 100 and FileVersion 10.0.15140.0 
        # 100 would become 10.0. and gets compared with first part of the FileVersion 10.0.

        $NavPID = Get-Process Microsoft.Dynamics.Nav.Server -ErrorAction SilentlyContinue | Where-Object FileVersion -like "$($NavVersionFolder.Insert(($NavVersionFolder.Length-1),".") + ".")*" | Select-Object -Property Id

        # Match the process to the service based on PID
        foreach ($processID in $NavServices.processID) {
            if ($processID -in $NavPID.Id) {
                        
                $ServicesToStop += $NavServices | Where-Object processID -eq $processID
            }

        }

    }

    return $ServicesToStop          
}


function Get-ProcessesToStop () {

    $ProcessesToStop = @()

    if ($MSOffice) {
        $ProcessesToStop += Get-Process OUTLOOK -ErrorAction SilentlyContinue | Select-Object -Property Product, Name, Id, FileVersion, Path
        $ProcessesToStop += Get-Process EXCEL -ErrorAction SilentlyContinue | Select-Object -Property Product, Name, Id, FileVersion, Path
        $ProcessesToStop += Get-Process WINWORD -ErrorAction SilentlyContinue | Select-Object -Property Product, Name, Id, FileVersion, Path
    }

    if ($NAVClient) {
        
        # Microsoft Dynamics NAV Windows RTC Client
        $ProcessesToStop += Get-Process Microsoft.Dynamics.Nav.Client -ErrorAction SilentlyContinue | Select-Object -Property Product, Name, Id, FileVersion, Path | Where-Object FileVersion -like "$($NavVersionFolder.Insert(($NavVersionFolder.Length-1),".") + ".")*"
            
        # Microsoft Dynamics NAV Development Environment
        $ProcessesToStop += Get-Process finsql -ErrorAction SilentlyContinue | Select-Object -Property Product, Name, Id, FileVersion, Path | Where-Object FileVersion -like "$($NavVersionFolder.Insert(($NavVersionFolder.Length-1),".") + ".")*"
            
        # Microsoft Dynamics NAV Administration Tool
        $ProcessesToStop += Get-Process mmc  -ErrorAction SilentlyContinue | Where-Object MainWindowTitle -like 'Microsoft Dynamics NAV Server*' | Select-Object -Property Product, Name, Id, FileVersion, Path
            
    }

    return $ProcessesToStop

}

function Get-ApplicationpoolsToStop () {
    
    $AppPools = @()
    $AppPoolsToStop = @()

    if ($WebServer) {

        $ws = (Get-NAVWebServerInstance -NavVersion $NavVersion).ApplicationPool | Get-Unique

        if ($ws -notin $AppPools) {

            $AppPools += $ws
        }
        $hs = (Get-NAVHelpInstance -NavVersion $NavVersion).ApplicationPool | Get-Unique

        if ($hs -notin $AppPools) {

            $AppPools += $hs
        }
    }

    if ($ApplicationPool) {
        foreach ($Pool in $ApplicationPool) {

            if ( -not (Get-WebAppPoolState -Name $("DynamicsNAV" + $NavVersionFolder + "Help") -ErrorAction SilentlyContinue)) {
                continue
            }

            if ($Pool -notin $AppPools) {

                $AppPools += $Pool
            }
        }
    }

    # Check the current status for the applicationpools

    foreach ($AppPool in $AppPools){
        $AppPoolState = Get-WebAppPoolState -Name $AppPool
        
        if ($AppPoolState.Value -eq 'Started') {

            $AppPoolsToStop += $AppPool
        }

        Remove-Variable AppPoolState
    }

    return $AppPoolsToStop
}

function Stop-MarkedServices ($ServicesToStop ) {

    $Message = "Do you want to stop the following service(s)? This is required to continue a cumulative update deployment. "
    $Message += "This script will not start the service(s) again."
    $Message += $($ServicesToStop | Format-List | Out-String)

    Write-Log -Path $LogPath -Message  $Message -Level Info

    if ($throw){

        $ErrorMsg = "All shown services need to be stopped to continue the execution of this script"
    } else {

        $ErrorMsg  = "Services won't be stopped"
    }

    # Prompt for user confirmation if mode is stopconfirm.

    if ($Mode -eq 'stopconfirm') {
        
        $Message = "Do you want to stop the following service(s)?: "
        $Message += $($ServicesToStop | Select-Object Name, ProcessId, State | Format-List | Out-String)
        $Message += "This is required to continue a cumulative update deployment. This script will not start the service(s) again."

        Show-MessageBox `
            -Message $Message `
            -Icon "Warning" `
            -ErrorMsg $ErrorMsg `
            -Throw:$Throw `
            -MessageType $MessageType `
            -Button 'YesNoCancel'
    } 
    
    if ($Mode -eq 'stopsilent') {

        $Message = "Automatically confirmed by executing this function in mode 'stopsilent'"
        Write-Log -Path $LogPath -Message  $Message -Level Info
    }

    # Stop Marked Services
    
    foreach ($NavService in $ServicesToStop) {

        $NavService.StopService() | Out-Null

        # Refresh service status

        $NavService = get-wmiobject win32_service | Where-Object Name -eq $($NavService.Name)

        While ($NavService.State -ne 'Stopped') {
            
            $Message = "Service $($NavService.Name) is stopping..."
            Write-Log -Path $LogPath -Message  $Message -Level Info
            Start-Sleep -Seconds 5

            # Refresh service status

            $NavService = get-wmiobject win32_service | Where-Object Name -eq $($NavService.Name)

        }

        $Message = "Service $($NavService.Name) is stopped."
        Write-Log -Path $LogPath -Message  $Message -Level Info

    }
}

function Stop-MarkedProcesses ($ProcessesToStop ) {
    
    $Message = "Do you want to stop the following process(es)? This is required to continue a cumulative update deployment. "
    $Message += "This script will not start the process(es) again. "
    $Message += $($ProcessesToStop | Format-List | Out-String)
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # Prompt for user confirmation if mode is stopconfirm.
    if ($throw){

        $ErrorMsg = "All shown processes need to be stopped to continue the execution of this script"
    } else {

        $ErrorMsg  = "Process(es) won't be stopped"
    }

    if ($Mode -eq 'stopconfirm') {

        Show-MessageBox `
            -Message "Do you want to stop the following process(es)?`n$($ProcessesToStop | Select-Object Name | Format-List | Out-String)This is required to continue a cumulative update deployment. This script will not start the process(es) again." `
            -Icon "Warning" `
            -ErrorMsg $ErrorMsg `
            -Throw:$Throw `
            -MessageType $MessageType `
            -Button 'YesNoCancel'
    } 
    
    if ($Mode -eq 'stopsilent') {

        $Message = "Automatically confirmed by executing this function in mode 'stopsilent'"
        Write-Log -Path $LogPath -Message  $Message -Level Info
    }

    # Stop Marked Processes

    foreach ($ProcessId in $ProcessesToStop.Id){

        if ($Mode -eq 'stopsilent' -or $Mode -eq 'stopconfirm') {
            
            # Use -Confirm instead of -Force while debugging to bypass the uservalidation
            Stop-Process -Id $ProcessId -Force -PassThru 
        }

        # To consider:
        # Quit client programs gracefully
        # $service.CloseMainWindow()
        # $OutlookRun.HasExited
    }
}

function Stop-MarkedApplicationpools ($AppPoolsToStop ) {

    $Message = "Do you want to stop the following applicationpool(s)? This is required to continue a cumulative update deployment. "
    $Message += "This script will not start the applicationpool(s) again. "
    $Message += $($AppPoolsToStop | Format-List | Out-String)
    Write-Log -Path $LogPath -Message  $Message -Level Info

    # Prompt for user confirmation if mode is stopconfirm.

    if ($Mode -eq 'stopconfirm') {

        #UserValidation

        Show-MessageBox `
            -Message $Message `
            -Icon "Warning" `
            -ErrorMsg $ErrorMsg `
            -Throw:$Throw `
            -MessageType $MessageType `
            -Button 'YesNoCancel'
    } 
    
    if ($Mode -eq 'stopsilent') {

        $Message = "Automatically confirmed by executing this function in mode 'stopsilent'"
        Write-Log -Path $LogPath -Message  $Message -Level Info
    }

    # Stop applicationpools

    foreach ($AppPool in $AppPoolsToStop){
        
        $AppPoolState = Get-WebAppPoolState -Name $AppPool
                
        if ($AppPoolState.Value -eq 'Started') {
            #ToDo: Try Catch?
            Stop-WebAppPool -Name $AppPool
        }

        # Validate action
        $AppPoolState = Get-WebAppPoolState -Name $AppPool
        
        while ( $((Get-WebAppPoolState -Name $AppPool).Value) -eq 'Stopping' ) {

            $Message = "Applicationpool '{0}' is stopping..." -f $AppPool
            Write-Log -Path $LogPath -Message  $Message -Level Info

            Start-Sleep -Seconds 1
            #ToDO: Prevent endless loop and break after few loops
        }

        
        if ($AppPoolState.Value -eq 'Stopped') {

            $Message = "Applicationpool '{0}' is stopped" -f $AppPool
            Write-Log -Path $LogPath -Message  $Message -Level Info
        } else {

            $Message = "Couldn't stop '{0}'. Current status is {1}" -f $AppPool, $AppPoolState.Value
            Write-Log -Path $LogPath -Message  $Message -Level Warn
        }

        Remove-Variable AppPoolState
    }
}

