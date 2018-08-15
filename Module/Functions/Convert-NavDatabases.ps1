<#
.SYNOPSIS
    This cmdlet converts multiple Dynamics NAV database to a newer version.

.DESCRIPTION
    After upgrading a NAV platform with a new cumulative update this cmdlet can convert multiple NAV database. 
    It will scan the host machine on configured NAV databases for the supplied NAV Version and execute Convert-NavDatabase for each database.

.PARAMETER NavVersion
    The NAV Version to get the distinct databases for. 
    Example: '2017', '2018', '2013 R2'
     
.EXAMPLE
    Convert-NavDatabases -NavVersion "2017" -Verbose

#>

function Convert-NavDatabases
{
    [CmdletBinding()]
    [OutputType([array])]
        
    param (
        [parameter(Mandatory=$true)]
        [string] $NavVersion,

        [Parameter(Mandatory=$false)]
        [switch] $SQLValidation = $false
    )

    Process 
    {
        # Define upgrade cmdlet template

        $UpgradeCmdletTemplate = "{0}Convert-NavDatabase -DatabaseName '{1}' -SQLDatabaseServer {2} -ServerInstance '{3}' -NavVersion {4} `n#### {5} #### `n"
        
        # Receive a list of unique database configured on the NAV Service Tiers on host machine

        $NavDatabases = Get-DistinctNavDatabases -NavVersion $NavVersion
        
        # List of Cmdlets to upgrade the databases seperatly

        $ToConvertDatabases = @()

        foreach ($Db in $NavDatabases) {

            # Concatenate SQL Server name and SQL Instance if SQL Instance exists

            if ($Db.DatabaseInstance -eq '') {
    
                $SQLDatabaseServer = $Db.DatabaseServer
            }
            else {
    
                $SQLDatabaseServer = "$($Db.DatabaseServer)\$($Db.DatabaseInstance)"
            }
            $DatabaseName = "$($Db.DatabaseName)"
            $ServerInstance = "$($Db.ServerInstance)"

            # Write current database in loop to host

            Write-Host ".."
            Write-Host "NAV $NavVersion database: $DatabaseName"
            Write-Host "SQL instance: $SQLDatabaseServer"
            Write-Host "Navision Server: $ServerInstance"

            $MarkCmdletAsText = ''
            $MarkComment = 'Database OK for upgrade.'

            # SQL Validaten (only possible if Dynamics NAV and SQL Server are installed on the same host)

            if ($SQLValidation) {

                # Check if SQL Instance is reachable

                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
                $SmoServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $SQLDatabaseServer

                $SmoServerName = $SmoServer.Name
                $SmoServerStatus = $SmoServer.Status

                if([string]::IsNullOrEmpty($SmoServer.Status)) {

                    $MarkCmdletAsText = '#'
                    $MarkComment = "SQL Server $SmoServerName not active. Check personal settings!"
                    $UpgradeCmdlet = $UpgradeCmdletTemplate -f $MarkCmdletAsText, '$DatabaseName', $SQLDatabaseServer, '$ServerInstance', $NavVersion, $MarkComment
                    $ToConvertDatabases += $UpgradeCmdlet
                    continue
                }
                else {

                    Write-Host "Status of SQL Server $SmoServerName is: $SmoServerStatus"
                }            

                # Check if SQL Database is reachable

                if (Verify-NAVDatabaseOnSql -DatabaseServer $SQLDatabaseServer -DatabaseName $DatabaseName) {
                
                    Write-Host "NAV Database $DatabaseName found on $SQLDatabaseServer"

                }

                else {
                    $MarkCmdletAsText = '#'
                    $MarkComment = "NAV Database $DatabaseName not found on $SQLDatabaseServer"
                    $UpgradeCmdlet = $UpgradeCmdletTemplate -f $MarkCmdletAsText, $DatabaseName, $SQLDatabaseServer, $ServerInstance, $NavVersion, $MarkComment
                    $ToConvertDatabases += $UpgradeCmdlet
                    continue
                }

                
                # Check if Database has correct Nav version
  
                $databaseversionno = Get-DatabaseversionnoBySqlcmd -SQLDatabaseServer $SQLDatabaseServer -DatabaseName $DatabaseName
                
                if ($databaseversionno -ge $MinimalBuild -and $databaseversionno -le $MaximumBuild) {
                    Write-Host "NAV Database $DatabaseName found on $SQLDatabaseServer"
                }

                else {
                    $MarkCmdletAsText = '#'
                    $MarkComment = "NAV Database $DatabaseName is build $databaseversionno"
                    $UpgradeCmdlet = $UpgradeCmdletTemplate -f $MarkCmdletAsText, $DatabaseName, $SQLDatabaseServer, $ServerInstance, $NavVersion, $MarkComment
                    $ToConvertDatabases += $UpgradeCmdlet
                    continue
                }

            }
            
            # Convert database to new platform cumulative update  
            
            $UpgradeCmdlet = $UpgradeCmdletTemplate -f $MarkCmdletAsText, $DatabaseName, $SQLDatabaseServer, $ServerInstance, $NavVersion, $MarkComment
            $ToConvertDatabases += $UpgradeCmdlet
            
        }

        return $ToConvertDatabases

    }
}

Export-ModuleMember -Function Convert-NavDatabases


<#
    .SYNOPSIS
        Verify that the database exists on provided SQL Server instance. 		
    .DESCRIPTION        
        Verify that the database exists on provided SQL Server instance. 		
    .PARAMETER DatabaseServer
        Specifies the SQL Server database server.
    .PARAMETER DatabaseInstance
        Specifies the SQL Server instance.
    .PARAMETER DatabaseName
        Specifies the database name.
#>
function Verify-NAVDatabaseOnSql 
{
    [CmdletBinding()]
    param
        (
            [parameter(Mandatory=$true)]
            [string]$DatabaseServer,
            
            [parameter(Mandatory=$true)]
            [string]$DatabaseName
        )
    
    Process
    {
        $CurrentLocation = Get-Location

        try {            

            $databaseExistsQuery = Invoke-Sqlcmd "IF EXISTS (SELECT 1 
                FROM sys.databases 
                WHERE name = '$DatabaseName') 
                SELECT 1 AS res ELSE SELECT 0 AS res;" -ServerInstance $DatabaseServer
 
            if($databaseExistsQuery.res -eq 0) {                
                
                return $false
            }

            return $true
        }

        finally {
            Set-Location $CurrentLocation
        }
    }
}
