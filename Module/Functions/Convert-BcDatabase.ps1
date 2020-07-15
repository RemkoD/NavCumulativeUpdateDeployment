function Convert-BcDatabase {
    Param(
        [Parameter(Mandatory=$true)]    
        [string] $ServerInstance,
        [switch] $Force
    )

    # Start Init
    $Symbols   = "\\fps01\Development\AL\16.3.14085.14238\.alpackages\Microsoft_System_16.0.14073.14195.app"
    $SystemApp = "\\fps01\Development\AL\16.3.14085.14238\.alpackages\Microsoft_System Application_16.3.14085.14238.app"

    Get-NavManagementModule -NavVersion $NavVersion -Import | Out-Null
    Get-NavAppsManagementModule -NavVersion $NavVersion -Import | Out-Null

    $SqlServer       = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseServer
    $SqlInstanceName = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseInstance
    $DatabaseName    = Get-NAVServerConfigurationValue -ServerInstance $ServerInstance -ConfigKeyName DatabaseName

    if($SqlInstanceName){
        $SqlInstance = '{0}\{1}' -f $SqlServer, $SqlInstanceName
    } else {
        $SqlInstance = $SqlServer
    }
    # End Init

    # Generate Script
    $ConvertDatabase = @() 
    $ConvertDatabase += "# Convert the Business Central database"
    $ConvertDatabase += "Invoke-NAVApplicationDatabaseConversion -DatabaseServer '{0}' -DatabaseName '{1}' -Force" -f $SqlInstance, $DatabaseName
    $ConvertDatabase += ''
    $ConvertDatabase += "# Start the Business Central Server Instance"
    $ConvertDatabase += "Set-NAVServerInstance -ServerInstance '{0}' -Start" -f $ServerInstance
    $ConvertDatabase += ''
    $ConvertDatabase += "# Unpublish Microsoft System Symbols"
    $ConvertDatabase += "Get-NAVAppInfo -ServerInstance '{0}' -SymbolsOnly | Unpublish-NAVApp" -f $ServerInstance
    $ConvertDatabase += ''
    $ConvertDatabase += "# Publish the System Symbols for the new platform release"
    $ConvertDatabase += "Publish-NAVApp -ServerInstance '{0}' -PackageType SymbolsOnly -Path '{1}'" -f $ServerInstance, $Symbols
    $ConvertDatabase += ''
    $ConvertDatabase += "# Sync the changes to SQL"
    $ConvertDatabase += "Sync-NAVTenant -ServerInstance '{0}' -Mode Sync -Force" -f $ServerInstance
    $ConvertDatabase += ''
    $ConvertDatabase += "# Uninstall Microsoft System Application"
    $ConvertDatabase += "Get-NAVTenant -ServerInstance '{0}' | ForEach-Object {{`n    Get-NAVAppInfo -ServerInstance `$_.ServerInstance -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' -Publisher 'Microsoft' | Uninstall-NAVApp -Tenant `$_.Id -Force `n}}" -f $ServerInstance
    $ConvertDatabase += ''
    $ConvertDatabase += "# Publish the new System Application"
    $ConvertDatabase += "Publish-NAVApp -ServerInstance '{0}' -Path '{1}' -SkipVerification" -f $ServerInstance, $SystemApp
    $ConvertDatabase += ''
    $ConvertDatabase += "# Unpublish previous System Application(s)"
    $ConvertDatabase += "Get-NAVAppInfo -ServerInstance '{0}' -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' -Publisher 'Microsoft' |`n    Where-Object -Property Version -ne `$(Get-NAVAppInfo -Path '{1}').Version | `n    Unpublish-NAVApp" -f $ServerInstance, $SystemApp
    $ConvertDatabase += ''
    $ConvertDatabase += "# Install the new System Application"
    $ConvertDatabase += "Get-NAVTenant -ServerInstance '{0}' | ForEach-Object {{" -f $ServerInstance
    $ConvertDatabase += "    Get-NAVAppInfo -ServerInstance `$_.ServerInstance -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' | Sync-NAVApp -Mode ForceSync -Tenant `$_.Id -Force"
    $ConvertDatabase += "    Get-NAVAppInfo -ServerInstance `$_.ServerInstance -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' | Start-NAVAppDataUpgrade -Tenant `$_.Id }"

    $ConvertDatabase | Write-Host

    if($Force){
        Write-Host 'Executing database conversion, please wait...'
        Invoke-Command -ScriptBlock $ConvertDatabase
        Write-Host 'Database conversion completed. Please update 4PS Construct now.'
    }

}

Export-ModuleMember -Function Convert-BcDatabase
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
        
        if([string]::IsNullOrEmpty($ConfigKeyValue))
        {
            Write-Error "The setting $ConfigKeyName could not be found in the configuration file of Microsoft Dynamics NAV Server $ServerInstance."
            return
        }

        return $configKeyValue.Value        
    }
}
