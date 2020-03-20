<#
.SYNOPSIS
    This cmdlet returns an array with all unique NAV databases configured on NAV Service Tiers on the host for a specific NAV Version.

.DESCRIPTION
    This cmdlet returns an array with all unique NAV databases configured on NAV Service Tiers on the host for a specific NAV Version.
    
    Designed to get a list of unique databases for a specific NAV Version to convert the databases after a cumulative update deployment.
    
    The cmdlet returns an array with hashtables containing the database name, database server, database instance and nav service instance.
 
.PARAMETER NavVersion
    The NAV Version to get the distinct databases for. 
    Example: '2017', '2018', '2013 R2'
 
.EXAMPLE
    Get-DistinctNavDatabase -NavVersion "2018"

.EXAMPLE
    Get-DistinctNavDatabase -NavVersion "2013 R2"
#>

function Get-DistinctNavDatabases
{
    [CmdletBinding()]
    [OutputType([array])]

    param (
        [parameter(Mandatory=$true)]
        [string] $NavVersion
    )

    Begin
    {

        Get-NavManagementModule -NavVersion $NavVersion -Import | Out-Null

        $Keys = @("DatabaseServer", "DatabaseInstance", "DatabaseName", "ServerInstance")

        $UniqueDatabases = @()

    }
 
    Process
    {
        
        # Get the NAV Server Instances for the supplied NAV Version
        $DisplayVersion = (Get-NavComponent -NavVersion $NavVersion | Where-Object Component -eq 'NST').DisplayVersion
        $NavInstances = Get-NAVServerInstance | Foreach-Object { 
            if ( ([Version] $_.Version).Major -eq ([version] $DisplayVersion).Major){ $_ } 
        }

        # Loop though the NAV Instances to generate a list of all unique NAV databases configured on the NSTs installed on the host machine

        foreach ($Instance in $NavInstances) {

            $NstValues = @{DatabaseServer = ''; DatabaseInstance  = ''; DatabaseName = ''; ServerInstance = ''}
    
            foreach ($Key in $Keys) {
        
                $NstValues.$Key = Get-NAVServerConfigurationValue -ServerInstance $Instance.ServerInstance -ConfigKeyName $Key

            }

            # To prevent duplicates in $UniqueDatabases caused by difference in SQL server 'localhost' and '[computername]'
            if ($NstValues.DatabaseServer -eq 'localhost') {

                $NstValues.DatabaseServer = $env:computername
            }

            # Check if the combination DatabaseServer,  DatabaseInstance and DatabaseName is already pressent. If not, add combination to $UniqueDatabases
            $Exists = $false
            foreach ($Db in $UniqueDatabases) {
        
                if ($Db.DatabaseName -eq $NstValues.DatabaseName -and `
                    $Db.DatabaseServer -eq $NstValues.DatabaseServer -and `
                    $Db.DatabaseInstance -eq $NstValues.DatabaseInstance) {
                    
                    $Exists = $true
                }
            }

            if (-not $Exists) {
                $UniqueDatabases += $NstValues
            }
        }
    }

    End 
    {
        
        return $UniqueDatabases
    }

}

Export-ModuleMember -Function Get-DistinctNavDatabases

# Function Get-NAVServerConfigurationValue is part of the Dynamics NAV Module 'NAVUpgradeCmdlets'. 
# Included here standalone to reduce dependencies. 

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
