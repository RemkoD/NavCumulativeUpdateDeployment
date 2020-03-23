
function Get-BCConvertDatabasesScript {
    param(
        [string] $NavVersion
    )
    $UniqueInstallations = Get-DistinctNavDatabases -NavVersion $NavVersion 
    
    $Scripts = @()
    foreach ($ServerInstance in $UniqueInstallations.ServerInstance){
        $Scripts += Get-BCConvertDatabaseScript -ServerInstance $ServerInstance -Verbose
    }

    return $Scripts

}

Export-ModuleMember -Function Get-BCConvertDatabasesScript