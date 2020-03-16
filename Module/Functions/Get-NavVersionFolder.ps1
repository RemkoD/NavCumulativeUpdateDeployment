<#
.Synopsis
    Returns the nav version and nav NavVersionFolder.

.DESCRIPTION
    Returns the nav version with the corresponding NavVersionFolder number in a hashtable variable. Returns $false if NavVersion is not valid.
    Usefull to get the nav version name (example: 2017) corresponding to the NavVersionFolder code (example: 100), or the other way around.

.EXAMPLE
    $NavVersion = Get-NAVNavVersionFolder -NavVersion nav2017
    $NavVersion.Version # is "2017"
    $NavVersion.NavVersionFolder # is "100"

.EXAMPLE
    $NavVersion = Get-NavVersionFolder -NavNavVersionFolder '100'
    $NavVersion.Version # is "2017"
    $NavVersion.NavVersionFolder # is "100"

.EXAMPLE
    $NavVersion = Get-NavVersionFolder -NavVersion 'nav2013r2'
    $NavVersion.Version # is "2013 R2"
    $NavVersion.NavVersionFolder # is "71"

.PARAMETER NavVersion
    The Nav Version, example: 'bc15', bc13', 'nav2018', 'nav2017', 'nav2013 R2'

.PARAMETER NavNavVersionFolder
    The Nav Version Folder, example: '150', '100', '71'
#>

function Get-NavVersionFolder
{
    [CmdletBinding(DefaultParameterSetName="NavVersion")]
    [OutputType([hashtable])]
    Param
    (
        
        [Parameter(Mandatory=$true, 
                    Position=0, 
                    ParameterSetName = "NavVersion")]

        [String] $NavVersion,

        [Parameter(Mandatory=$true,
                    Position=0, 
                    ParameterSetName = "NavNavVersionFolder")]
        
        [String] $NavNavVersionFolder
    )

    Begin
    {
        
        [hashtable] $Version = @{Version = ''; NavVersionFolder = ''; ProductAbb = '';}
    }
    
    Process
    {
        
        if ($NavVersion -eq "bc15" -or $NavNavVersionFolder -eq "150") {
            $Version.Version = "bc15"
            $Version.NavVersionFolder = "150"
            $Version.ProductAbb = 'BC'
        }
        if ($NavVersion -eq "bc14" -or $NavNavVersionFolder -eq "140") {
            $Version.Version = "bc14"
            $Version.NavVersionFolder = "140"
            $Version.ProductAbb = 'BC'
        }
        if ($NavVersion -eq "bc13" -or $NavNavVersionFolder -eq "130") {
            $Version.Version = "bc13"
            $Version.NavVersionFolder = "130"
            $Version.ProductAbb = 'BC'
        }
        if ($NavVersion -eq "nav2018" -or $NavNavVersionFolder -eq "110") {
            $Version.Version = "2018"
            $Version.NavVersionFolder = "110"
            $Version.ProductAbb = 'NAV'
        }
        if ($NavVersion -eq "nav2017" -or $NavNavVersionFolder -eq "100") {
            $Version.Version = "2017"
            $Version.NavVersionFolder = "100"
            $Version.ProductAbb = 'NAV'
        }
        if ($NavVersion -eq "nav2016" -or $NavNavVersionFolder -eq "90") {
            $Version.Version = "2016"
            $Version.NavVersionFolder = "90"
            $Version.ProductAbb = 'NAV'
        }
        if ($NavVersion -eq "nav2015" -or $NavNavVersionFolder -eq "80") {
            $Version.Version = "2015"
            $Version.NavVersionFolder = "80"
            $Version.ProductAbb = 'NAV'
        }
        if ($NavVersion -like '*2013R2' -or $NavVersion -like '*2013 R2' -or $NavNavVersionFolder -eq "71") {
            $Version.Version = "2013 R2"
            $Version.NavVersionFolder = "71"
            $Version.ProductAbb = 'NAV'
        }

        if(-not $Version.Version){
            return $false
        }

        return $Version
    }
    
}

Export-ModuleMember -Function Get-NavVersionFolder