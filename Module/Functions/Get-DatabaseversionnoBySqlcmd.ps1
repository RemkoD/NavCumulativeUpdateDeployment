<#
.SYNOPSIS
    Gets the databaseversion of a given NAV database
    
.DESCRIPTION
    Gets the databaseversion of a given NAV database
    
.EXAMPLE
    $databaseversionno = Get-DatabaseversionnoBySqlcmd -SQLDatabaseServer localhost -DatabaseName MyDatabase
    
.EXAMPLE
    $databaseversionno = Get-DatabaseversionnoBySqlcmd -SQLDatabaseServer localhost\SQL2016 -DatabaseName MyDatabase
    
.PARAMETER SQLDatabaseServer
    The server instance, eg. 'localhost' or 'srv1\myinstance'
    
.PARAMETER DatabaseName
    The database name
#>
function Get-DatabaseversionnoBySqlcmd {
    [cmdletbinding()]
    PARAM
    (
        [parameter(Mandatory=$true)]
        [string]$SQLDatabaseServer,
        [parameter(Mandatory=$true)]
        [string]$DatabaseName
    )
    PROCESS
    {
        $databaseversionno = Invoke-Sqlcmd -ServerInstance $SQLDatabaseServer -Database $DatabaseName -Query 'SELECT TOP (1) [databaseversionno] FROM [dbo].[$ndo$dbproperty]'
        return $databaseversionno."databaseversionno"
    }
}

Export-ModuleMember -Function Get-DatabaseversionnoBySqlcmd