param(
    [String] $ServerInstance,
    [string] $NavVersion = 'bc16',
    [string] $SystemPath = "\\fps01\Development\AL\16.5.15897.15953\.alpackages\Microsoft_System_16.0.15884.15941.app",
    [string] $SystemApplicationPath = "\\fps01\Development\AL\16.5.15897.15953\.alpackages\Microsoft_System Application_16.5.15897.15953.app"
)
$ScriptRootPath = $PSScriptRoot
Write-Host "$ScriptRootPath\Load Deployment Settings.ps1"
. "$ScriptRootPath\Load Deployment Settings.ps1"

Convert-BcDatabase `
    -ServerInstance $ServerInstance `
    -NavVersion $NavVersion `
    -SystemPath $SystemPath `
    -SystemApplicationPath $SystemApplicationPath