function Get-BCConvertDatabaseScript {
    param(
        [Parameter(Mandatory=$true)]    
        [string] $ServerInstance,
        [Parameter(Mandatory=$true)]
        [string] $NavVersion
    )

    Get-NavManagementModule -NavVersion $NavVersion -Import | Out-Null
    Get-NavAppsManagementModule -NavVersion $NavVersion -Import | Out-Null
    
    'Working on ServiceInstance {0}' -f $ServerInstance | Write-Verbose

    $StopFlag = $false
    if((Get-NAVServerInstance -ServerInstance $ServerInstance).State -ne 'Running'){
        $StopFlag = $true

        'ServiceInstance {0} is not running, starting instance..' -f $ServerInstance | Write-Verbose

        Set-NAVServerInstance -ServerInstance $ServerInstance -Start -ErrorAction Continue

        if((Get-NAVServerInstance -ServerInstance $ServerInstance).State -ne 'Running'){
            'Could not start service, skipping ServiceInstance {0}' -f $ServerInstance | Write-Warning
            return
        }
    }

    'Retreiving installed apps from ServiceInstance {0}..' -f $ServerInstance | Write-Verbose

    $PublishedApps = Get-NAVAppInfo -ServerInstance $ServerInstance
    $InstalledApps = $PublishedApps | ForEach-Object {
        $TenantsWithApp = Get-NAVAppTenant -ServerInstance $ServerInstance -Name $_.Name
        if ($TenantsWithApp.State -contains 'Operational'){ $_ }
    
    } 
    # Sort the installed app on the right installation order.
    if($InstalledApps){

        $InstalledApps = Get-AppDependencyOrder -ServerInstance $ServerInstance -Apps $InstalledApps
        $InstalledAppsReverse = $InstalledApps | Sort-Object -Property ProcessOrder -Descending

        # Generate the uninstall and install scripts
        $Uninstall = @()
        $Install =  @()
        $InstalledApps | ForEach-Object {
            $Install   += "Install-NAVApp -ServerInstance '{0}' -Name '{1}' -Version '{2}'" -f $ServerInstance, $_.Name, $_.Version
        }
        $InstalledAppsReverse | ForEach-Object {
            $Uninstall += "Uninstall-NAVApp -ServerInstance '{0}' -Name '{1}' -Version '{2}'" -f $ServerInstance, $_.Name, $_.Version
        }
    }

    # Generate the convert database script
    $SqlServer       = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseServer
    $SqlInstanceName = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseInstance
    $DatabaseName    = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseName

    if($SqlInstanceName){
        $SqlInstance = '{0}\{1}' -f $SqlServer, $SqlInstanceName
    } else {
        $SqlInstance = $SqlServer
    }
    $ConvertDatabase = @()
    
    $ConvertDatabase += "Invoke-NAVApplicationDatabaseConversion -DatabaseServer '{0}' -DatabaseName '{1}'" -f $SqlInstance, $DatabaseName
    $ConvertDatabase += "Set-NAVServerInstance -ServerInstance '{0}' -Start" -f $ServerInstance
    $ConvertDatabase += "Sync-NAVTenant -ServerInstance '{0}' -Mode Sync" -f $ServerInstance

    # Uninstall before stop? 
    
    if($StopFlag){
        # Set-NAVServerInstance -ServerInstance $ServerInstance -Stop
    }
    return [ordered] @{'ToUninstall' = $Uninstall; 'ToConvert' = $ConvertDatabase; 'ToInstall' = $Install}
}

Export-ModuleMember -Function Get-BCConvertDatabaseScript

function Get-AppDependencyOrder {
    [CmdletBinding(DefaultParameterSetName='FilePath')]
    param(            
        [Parameter(Mandatory=$true, ParameterSetName = "FilePath")]
        [string[]] $Path,
        [Parameter(Mandatory=$true, ParameterSetName = "AppObject")]
        [object[]] $Apps,
        [Parameter(Mandatory=$true, ParameterSetName = "AppObject")]
        [string] $ServerInstance
    )

    if($PSCmdlet.ParameterSetName -eq 'FilePath'){
        
        $AllAppFiles = @()
        $Path | ForEach-Object {
            $AllAppFiles += Get-ChildItem -Path $_ -Recurse -Filter "*.app"
        }

        $AllApps = @()
        foreach ($AppFile in $AllAppFiles) {
            $App = Get-NAVAppInfo -Path $AppFile.FullName
            $AllApps += [PSCustomObject]@{
                AppId        = $App.AppId
                Version      = $App.Version
                Name         = $App.Name
                Publisher    = $App.Publisher
                ProcessOrder = 0                            
                Dependencies = $App.Dependencies
                Path         = $AppFile.FullName}
        }
    }

   if($PSCmdlet.ParameterSetName -eq 'AppObject'){
        $AllApps = @()
        foreach ($App in $Apps) {
            $App = Get-NAVAppInfo -ServerInstance $ServerInstance -Id $App.AppId.Value.Guid
            $AllApps += [PSCustomObject]@{
                    AppId        = $App.AppId
                    Version      = $App.Version
                    Name         = $App.Name
                    Publisher    = $App.Publisher
                    ProcessOrder = 0                            
                    Dependencies = $App.Dependencies
                    Path         = 'unknown'}
        }
   }
 
    $FinalResult = @()

    $AllApps | ForEach-Object {    
        $FinalResult = Add-BCAppToDependencyTree `
                            -App $_ `
                            -DependencyArray $FinalResult `
                            -AppCollection $AllApps `
                            -Order $AllApps.Count
    }

    return $FinalResult | Sort-Object ProcessOrder

}

function Add-BCAppToDependencyTree() {
    param(
        [PSObject] $App,
        [PSObject[]] $DependencyArray,
        [PSObject[]] $AppCollection,
        [Int] $Order = 1
    )   

    foreach ($Dependency in $App.Dependencies) {
        $DependencyArray = Add-BCAppToDependencyTree `
                                -App ($AppCollection | Where-Object AppId -eq $Dependency.AppId) `
                                -DependencyArray $DependencyArray `
                                -AppCollection $AppCollection `
                                -Order ($Order - 1)
    }

    if (-not($DependencyArray | Where-Object AppId -eq $App.AppId)) {
        if($App.AppId){
            $DependencyArray += $App
            ($DependencyArray | Where-Object AppId -eq $App.AppId).ProcessOrder = $Order
        } 
    }
    else {
        if (($DependencyArray | Where-Object AppId -eq $App.AppId).ProcessOrder -gt $Order) {
            ($DependencyArray | Where-Object AppId -eq $App.AppId).ProcessOrder = $Order
        } 
    }

    $DependencyArray
}
function Get-NAVServerConfigurationValue
{
    param
    (
     [parameter(Mandatory=$true)]
     [string]$ServerInstance,
    
     [parameter(Mandatory=$true)]
     [string]$ConfigKeyName
    )
    PROCESS
    {
        $config = Get-NAVServerConfiguration -ServerInstance $ServerInstance -AsXml
        $configSettings = $config.GetElementsByTagName("add");

        $configKeyValue = $configSettings | Where-Object { $_.Attributes["key"].Value -eq $ConfigKeyName } 
        
        if($ConfigKeyValue -eq $null)
        {
            Write-Error "The setting $ConfigKeyName could not be found in the configuration file of Microsoft Dynamics NAV Server $ServerInstance."
            return
        }

        return $configKeyValue.Value        
    }
}
