## Part 1 - Preparation

### Deployment options for the CU patch
If you've followed the instructions from *'01 How to prepare a deployment package'* you will have a deployment package that looks something like this:

```
Upgrade NAV CU package
│   Load Deployment Settings.ps1
│   Step 1 - Install NAV Platform Cumulative Update.ps1 
│   Step 2 - Generate 'Upgrade NAV Databases'.ps1
└───Cumulative Updates
│   └───NAV2017_W1_CU17_Build_10.0.21440.0
│       │───ADCS
│       │───BPA
│       │───...
└───Module
    │   NavCumulativeUpdateDeployment.psd1
    │   NavCumulativeUpdateDeployment.psm1
    └───Functions
        │───Convert-NAVDatabase.ps1
        │───Convert-NAVDatabases.ps1
        │───...
```

**Option 1** (easiest): You can copy the whole *'Upgrade NAV CU package'* folder to every system you are going to upgrade. 

**Option 2**: You can execute the scripts and access the module and CU files from a network share. If you want to use option 2 you have to change the location of the cumulative update folder and the PowerShell module folder in the *'Load Deployment Settings.ps1'* file.

``` PS
# Example
# Change the following variables in 'Load Deployment Settings.ps1’
  $CumulativeUpdateLocation = Join-Path -Path $ScriptRootPath -ChildPath "Cumulative Updates"
  $CUDeploymentModulePath = Join-Path -Path $ScriptRootPath -ChildPath "Module\NavCumulativeUpdateDeployment.psm1"
# to your network share location
  $CumulativeUpdateLocation = "\\server\share\upgrade nav cu package\cumulative update\NAV2017_NL_CU16_Build_10.0.20784.0\"
  $CUDeploymentModulePath = "\\server\share\upgrade nav cu package\module\NavCumulativeUpdateDeployment.psm1"
```

**Option 3**: Make something fancy yourself. These are example scripts after all. 

### Make a backup
Before you are going to convert the NAV database(s) to a higher CU: **Make sure you've made a backup from your NAV database.**
Because the filesystem will be updated I recommend to make a **snapshot** first, if you're using virtual servers. The example script will make a backup from the files before upgrading them. But rolling back to a snapshot is way easier. 

Really, backups are important. A CU update is not that exciting and dangerous. But if anything goes wrong you want to be able to rollback. Just in case Microsoft, this script or maybe even yourself made a tiny mistake. We're all humans after all. 

## Part 2 - The CU installation
 * Copy the 'Upgrade NAV CU package' files to a system you want to upgrade.
 * Open PowerShell ISE as Administrator.
 * Change the execution policy by executing the following two Cmdlets
 
 ``` PS
 Set-ExecutionPolicy -ExecutionPolicy Unrestricted
 Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted 
 ```
 
 * Open the files **Step 1 - Install NAV Platform Cumulative Update.ps1** on the local system.
 * Execute the script with the green play button or with the hotkey **F5**
   The script will stop active services, processes and IIS application pools that are locking the NAV files.
   Multiple pop-ups can appear with the question to stop certain services/processes or application pools. 
 * If a pop-ups asks to close applications: click yes to continue.
 * If all validation's have passed you get a question if you want to continue with the upgrade, click yes.

The Cumulative Update installation on this machine is done! All found NAV components are upgraded. The script will show in a pop-up which components are found and upgraded. 

 * Repeat above steps for each server and client machine you want to upgrade.

**Tip:**
The script won't start stopped services again. It's best to keep all services stopped until all application servers are upgraded and the NAV databases are converted. After the installation and database conversion you can start the services *manually*   or you can *restart the server*. If you are not sure which services to start again it's best to restart the server. Or you could check the host output or log file from the PowerShell script to check which services are stopped.

## Part 3 - The NAV database conversion
**Assumptions**: 
 * The scripts are already on the application server from part 2 and the CU is already installed.
 * There are no active sessions to the NAV database (on SQL level) anymore. 
*You can check the active sessions on the NAV database from the SQL Management Studio > Activity Monitor > Processes*

**Steps:**
 * Open PowerShell ISE as Administrator
 * Open the file **Step 2 - Generate 'Upgrade NAV Databases'.ps1**
 * Execute the script with the green play button or with the hotkey **F5**
 The scrip will create a new file in the script root directory and opens this script in a new tab in PowerShell ISE.

``` PS
# Example
Convert-NAVDatabase -DatabaseName 'NAV100Prod' -SQLDatabaseServer SQLServer\SQLInstance -ServerInstance 'DynamicsNAV100' -NavRelease 2017 
Convert-NAVDatabase -DatabaseName 'NAV100Test' -SQLDatabaseServer SQLServer\SQLInstance -ServerInstance 'DynamicsNAV100Test' -NavRelease 2017 
```

 * Select one row with the NAV database you want to upgrade
 * Execute this line with the run selection button or with the hotkey **F8**
 * Repeat this step for each NAV database you want to upgrade

The NAV database conversion is done! 

**Note:** Converting a NAV database is an irreversible action. Going back requires a backup from the database.

## Part 4 - Start NAV environment and test the results
Start the NAV environment again. Easiest option is to restart the NAV application servers. Starting the NST services and IIS application apools manual is possible too of course. 

After that. You know... open the NAV clients and do a few clicks around. Check the build numbers. Enjoy a beer to celebrate. Or work like crazy until sunrise to fix any problem you encounter. The usual stuff. 

