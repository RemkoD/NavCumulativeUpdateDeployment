function Convert-BcDatabase {
    Param(
        [Parameter(Mandatory=$true)]    
        [string] $ServerInstance,
        [Parameter(Mandatory=$true)]    
        [string] $NavVersion,
        [Parameter(Mandatory=$true)]    
        [string] $SystemPath,
        [Parameter(Mandatory=$true)]    
        [string] $SystemApplicationPath,
        
        [switch] $Force
    )

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
    $ConvertDatabase += "### Parameters ###"
    $ConvertDatabase += "`$ServerInstance        = '{0}'" -f $ServerInstance
    $ConvertDatabase += "`$SqlInstance           = '{0}'" -f $SqlInstance
    $ConvertDatabase += "`$DatabaseName          = '{0}'" -f $DatabaseName
    $ConvertDatabase += ''
    $ConvertDatabase += "`$SystemPath            = '{0}'" -f $SystemPath
    $ConvertDatabase += "`$SystemApplicationPath = '{0}'" -f $SystemApplicationPath
    $ConvertDatabase += ''
    $ConvertDatabase += "# Convert the Business Central database"
    $ConvertDatabase += 'Invoke-NAVApplicationDatabaseConversion -DatabaseServer $SqlInstance -DatabaseName $DatabaseName -Force'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Start the Business Central Server Instance"
    $ConvertDatabase += 'Set-NAVServerInstance -ServerInstance $ServerInstance -Start'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Unpublish Microsoft System Symbols"
    $ConvertDatabase += 'Get-NAVAppInfo -ServerInstance $ServerInstance -SymbolsOnly | Unpublish-NAVApp'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Publish the System Symbols for the new platform release"
    $ConvertDatabase += 'Publish-NAVApp -ServerInstance $ServerInstance -PackageType SymbolsOnly -Path $SystemPath'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Sync the changes to SQL"
    $ConvertDatabase += 'Sync-NAVTenant -ServerInstance $ServerInstance -Mode Sync -Force'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Uninstall Microsoft System Application"
    $ConvertDatabase += "Get-NAVTenant -ServerInstance `$ServerInstance | ForEach-Object {`n    Get-NAVAppInfo -ServerInstance `$_.ServerInstance -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' -Publisher 'Microsoft' | Uninstall-NAVApp -Tenant `$_.Id -Force `n}"
    $ConvertDatabase += ''
    $ConvertDatabase += "# Publish the new System Application"
    $ConvertDatabase += 'Publish-NAVApp -ServerInstance $ServerInstance -Path $SystemApplicationPath -SkipVerification'
    $ConvertDatabase += ''
    $ConvertDatabase += "# Unpublish previous System Application(s)"
    $ConvertDatabase += "Get-NAVAppInfo -ServerInstance `$ServerInstance -Id '63ca2fa4-4f03-4f2b-a480-172fef340d3f' -Publisher 'Microsoft' |`n    Where-Object -Property Version -ne `$(Get-NAVAppInfo -Path `$SystemApplicationPath).Version | `n    Unpublish-NAVApp"
    $ConvertDatabase += ''
    $ConvertDatabase += "# Install the new System Application"
    $ConvertDatabase += 'Get-NAVTenant -ServerInstance $ServerInstance | ForEach-Object {{'
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
