param(
    [String] $ServerInstance,
    [string] $NavVersion = 'bc15'
)
$ScriptRootPath = $PSScriptRoot
Write-Host "$ScriptRootPath\Load Deployment Settings.ps1"
. "$ScriptRootPath\Load Deployment Settings.ps1"

$Script = Get-BCConvertDatabaseScript -ServerInstance $ServerInstance -NavVersion 'bc15'

#foreach ($Key in $Script.Keys){ $Script.$Key | Out-String }

"### Generated script : Convert {0} database configured on ServerInstance '{1}' ###" -f $NavVersion, $ServerInstance | Write-Host -ForegroundColor Green
"### Copy the script below and paste it in PowerShell ISE. ###" | Write-Host -ForegroundColor Green
"### Save the file on disk, PowerShell ISE needs to be restarted during the installation. ###" | Write-Host -ForegroundColor Green
"### follow the steps to convert the database configured on ServerInstance '{0}' ###`n`n" -f $ServerInstance | Write-Host -ForegroundColor Green
"# Step 1: Before deploying the cumulative update you've to uninstall all installed BC Apps, including the system app. `n" | Write-Host -ForegroundColor Green

$Script.ToUninstall | Out-String | Write-Host -ForegroundColor Yellow

"# Step 2: Close PowerShell ISE. Required to unload the BC PowerShell modules that are updated in the next step. `n" | Write-Host -ForegroundColor Green

"# Step 3: Deploy the cumulative update patch by executing script:" | Write-Host -ForegroundColor Green
"# '{0}'" -f (Join-Path $ScriptRootPath 'Install Platform Cumulative Update.ps1') | Write-Host -ForegroundColor Green
"# Open the script in PowerShell ISE and execute the script.`n" | Write-Host -ForegroundColor Green

"# Step 4: Convert the database.`n" | Write-Host -ForegroundColor Green

$Script.ToConvert | Out-String | Write-Host -ForegroundColor Yellow

"# Step 5: Install the apps that where uninstalled in step 1.`n" | Write-Host -ForegroundColor Green

$Script.ToInstall | Out-String | Write-Host -ForegroundColor Yellow