<#
.Synopsis
    Shows a pop-up window with the supplied message and optional buttons the user can choose from. 

.DESCRIPTION
    This function is needs refactoring. 

.EXAMPLE
    $Message = "Hello World"
    Show-MessageBox -Message $Message -Icon "Information" -Button 'OK'

.EXAMPLE
    $Message = "End of World, don't you agree?"
    $ErrorMsg = "Error, climate change found!"
    Show-MessageBox `
            -Message $Message `
            -Icon "Warning" `
            -ErrorMsg $ErrorMsg `
            -Throw:$Throw `            -MessageType "MessageBox" `
            -Button 'YesNo'

.PARAMETER Message
    The message to show to the user

.PARAMETER WindowTitle
    The messagebox window title

.PARAMETER Icon
    The icon type to be shown in the messagebox. For example a question mark or an error cross. 
    Options 'None', 'Question', 'Error', 'Warning' or 'Information' are valid

.PARAMETER ErrorMsg
    Error message shown when user used No or Cancel button

.PARAMETER Throw
    Throws an exception and ends script execution if parameter is true and users chose a No or Cancel button.

.PARAMETER MessageType
    Shows a messagebox question or a inshell question. Valid options are: 'InShell', 'MessageBox'.

.PARAMETER Button
    Shows one or more button to the user. Valid options are: 'OK', 'OKCancel', 'YesNo', 'YesNoCancel'.
    Only supported for MessageType MessageBox, InShell is always YesNo 
    
#>
function Show-MessageBox ()
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $Message,
        
        [Parameter(Mandatory=$false)]
        [string] $WindowTitle = 'Dynamics NAV CU Deployment',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('None', 'Question', 'Error', 'Warning', 'Information')]
        [string] $Icon = 'Information',
        
        [Parameter(Mandatory=$false)]
        [string] $ErrorMsg = 'A not specified error occurred',

        [Parameter(Mandatory=$false)]
        [switch] $Throw = $false,

        [Parameter(Mandatory=$false)]
        [ValidateSet('InShell', 'MessageBox')]
        [string] $MessageType = 'MessageBox',

        # Only supported for MessageBox, InShell is always YesNo
        [Parameter(Mandatory=$false)]
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')]
        [string] $Button = 'OK'
    )

    Begin
    {
        if ($MessageType -eq 'MessageBox') {
            
            Add-Type -AssemblyName PresentationFramework
        }
    }
    Process
    {
        
        if ($MessageType -eq 'MessageBox') {

            $Results = [System.Windows.MessageBox]::Show($Message, $WindowTitle, $Button ,$Icon)

            If (($Results -eq 'No' -or $Results -eq 'Cancel')) {
            
                [System.Windows.MessageBox]::Show($ErrorMsg, 'Script could not complete', 'OK','Error')
            
                if ($Throw) {

                    throw $ErrorMsg
                }
            }

            return

        } # End If messagebox

        if ($MessageType -eq 'InShell') {

            $Results = Read-Host "Yes or No"

            While ("yes","y","no","n" -notcontains $Results) {
                
                $Results = Read-Host "Please answer Yes or No"
            }
            
            If ($Results -eq "no" -or $Results -eq "n") {
              
                if ($Throw) {

                    throw $ErrorMsg
                }

            } Else {
                
                Write-Host "Ok. Proceeding to next step..."
                return
            }

        } # End If InShell
    }
    End
    {
        
    }
}


Export-ModuleMember -Function Show-MessageBox

function UserValidation ()
{

    $answer = Read-Host "Yes or No"

    while ("yes","y","no","n" -notcontains $Answer)
    {
        $Answer = Read-Host "Please answer Yes or No"
    }
    if ($Answer -eq "no" -or $Answer -eq "n") {

        Write-Host "Not proceeding..."
        throw "User cancelled stop service, process or applicationpool action." 

    } else {
        Write-Host "Ok. Proceeding to next step..."
        return
    }
}