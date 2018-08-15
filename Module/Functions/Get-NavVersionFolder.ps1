<#
.Synopsis
    Returns the nav version and nav NavVersionFolder.

.DESCRIPTION
    Returns the nav version with the corresponding NavVersionFolder number in a hashtable variable. Returns $false if NavVersion is not valid.
    Usefull to get the nav version name (example: 2017) corresponding to the NavVersionFolder code (example: 100), or the other way around.

.EXAMPLE
    $NavVersion = Get-NAVNavVersionFolder -NavVersion 2017
    $NavVersion.Version # is "2017"
    $NavVersion.NavVersionFolder # is "100"

.EXAMPLE
    $NavVersion = Get-NavVersionFolder -NavNavVersionFolder '100'
    $NavVersion.Version # is "2017"
    $NavVersion.NavVersionFolder # is "100"

.EXAMPLE
    $NavVersion = Get-NavVersionFolder -NavVersion '2013r2'
    $NavVersion.Version # is "2013 R2"
    $NavVersion.NavVersionFolder # is "71"

.PARAMETER NavVersion
    The Nav Version, example: '2017', '2018', '2013 R2'

.PARAMETER NavNavVersionFolder
    The Nav Version Folder, example: '100', '110', '71'
#>

function Get-NavVersionFolder
{
    [CmdletBinding(DefaultParameterSetName="NavVersion")]
    [Alias()]
    [OutputType([hashtable])]
    Param
    (
        
        [Parameter(Mandatory=$true, 
                    ValueFromPipelineByPropertyName=$false, 
                    Position=0, 
                    ParameterSetName = "NavVersion")]

        [String] $NavVersion,

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$false,
                    Position=0, 
                    ParameterSetName = "NavNavVersionFolder")]
        
        [String] $NavNavVersionFolder
    )

    Begin
    {
        
        [hashtable] $Version = @{Version = ''; NavVersionFolder = '';}
    }
    
    Process
    {
        if ($NavVersion -eq "2018" -or $NavNavVersionFolder -eq "110") {
            $Version.Version = "2018"
            $Version.NavVersionFolder = "110"
        }
        elseif ($NavVersion -eq "2017" -or $NavNavVersionFolder -eq "100") {
            $Version.Version = "2017"
            $Version.NavVersionFolder = "100"
        }
        elseif ($NavVersion -eq "2016" -or $NavNavVersionFolder -eq "90") {
            $Version.Version = "2016"
            $Version.NavVersionFolder = "90"
        }
        elseif ($NavVersion -eq "2015" -or $NavNavVersionFolder -eq "80") {
            $Version.Version = "2015"
            $Version.NavVersionFolder = "80"
        }
        elseif ($NavVersion -eq "2013R2" -or $NavVersion -eq "2013 R2" -or $NavNavVersionFolder -eq "71") {
            $Version.Version = "2013 R2"
            $Version.NavVersionFolder = "71"
        }
        else {
            
            return $false

        }

        return $Version
    }
    
    End
    {
        
    }
}

Export-ModuleMember -Function Get-NavVersionFolder