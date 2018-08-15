<#
.SYNOPSIS
    This cmdlet converts a Dynamics NAV database to a newer version.

.DESCRIPTION
    After upgrading a NAV platform with a new cumulative update this cmdlet can convert the NAV database. 
    Designed to convert one database. 

.PARAMETER NavVersion
    The NAV version to get the distinct databases for. 
    Example: '2017', '2018', '2013 R2'
     
.PARAMETER ServerInstance
    The Microsoft Dynamics NAV Service Tier that is going to be used for Sync-NAVTenant (to synchronize the NAV table definition with the SQL database).
 
.PARAMETER DatabaseName
    The Microsoft Dynamics NAV Database that you want to convert.

.PARAMETER SQLDatabaseServer
    The SQL Server + SQL Instance name. 
    Example: "SQLServer\MSSQL2017".
    Supply only the SQL Server name if the default MSSQL instance is used.

.EXAMPLE
    Convert-NavDatabase -ServerInstance "DynamicsNAV100" -DatabaseName "Demo Database NAV (10-0)" -SQLDatabaseServer "localhost" -NavVersion '2017'

.EXAMPLE
    Convert-NavDatabase -ServerInstance "DynamicsNAV100" -DatabaseName "Demo Database NAV (10-0)" -SQLDatabaseServer "localhost\MSSQL2017" -NavVersion '2017'

#>

function Convert-NavDatabase
{
    [CmdletBinding()]
    
    param (
        [parameter(Mandatory=$true)]
        [string] $NavVersion,
        
        [parameter(Mandatory=$true)]
        [string] $ServerInstance,

        [parameter(Mandatory=$true)]
        [string] $DatabaseName,

        [parameter(Mandatory=$true)]
        [string] $SQLDatabaseServer

    )
    
    Begin
    {

		Get-NavModelToolsModule -NavVersion $NavVersion -Import

    }

    Process
    {

    # Stop the Service Instance

        Set-NAVServerInstance -ServerInstance $ServerInstance -Stop -Force -Verbose

    # Convert database to new version 

        Invoke-NAVDatabaseConversion -DatabaseName $DatabaseName -DatabaseServer $SQLDatabaseServer -Verbose

    # Recompile Microsoft Dynamics NAV system tables

    #    Compile-NAVApplicationObject -DatabaseName $DatabaseName -DatabaseServer $SQLDatabaseServer -Filter "Type=Table;ID=2000000000.." -SynchronizeSchemaChanges no -Recompile  -AsJob -Verbose | Receive-Job -Wait -Verbose

    # Start a Microsoft Dynamics NAV 2017 Server Instance connected to the Converted Database

        Set-NAVServerInstance -ServerInstance $ServerInstance -ReStart -Verbose

    # Run the schema synchronization to complete the database conversion

        Sync-NAVTenant -ServerInstance $ServerInstance -Mode Sync -Force -Verbose

    # Restart the Service Instance

        Set-NAVServerInstance -ServerInstance $ServerInstance -Stop -Force -Verbose

    }
}

Export-ModuleMember -Function Convert-NavDatabase