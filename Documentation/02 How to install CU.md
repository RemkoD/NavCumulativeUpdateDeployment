## Part 1 - Preparation

### Deployment options for the CU patch
If you have followed the instructions from *'01 How to prepare a deployment package'* you will have a deployment package that looks like this:

```
Upgrade NAV CU package
│   Load Deployment Settings.ps1
│   Step 1 - Install NAV Platform Cumulative Update.ps1 
│   Step 2 - Generate 'Upgrade NAV Databases'.ps1
└───Cumulative Updates
│   └───NAV2017_W1_CU17_Build_10.0.21440.0
│       │───ADCS
│       │───...
└───Module
    │   NavCumulativeUpdateDeployment.psd1
    │   NavCumulativeUpdateDeployment.psm1
    └───Functions
        │───Convert-NAVDatabase.ps1
        │───...
```

**Option 1**: You can copy the whole *'Upgrade NAV CU package'* folder to every system you are going to upgrade. 

**Option 2**: You can execute the scripts and access the module and CU files from a network share. 

**Option 3**: Feel free to create something fancy yourself (Remote Powershell or GPO?). These are example scripts after all. 

### Make a backup
Before you are going to convert the NAV database(s) to a higher CU: **Make sure you have made a backup of your NAV database.**
Since the filesystem will be updated, I recommend making a **snapshot** first, if you are using virtual servers. The example script will make a backup of the files before upgrading them. But rolling back to a snapshot is much easier. 

Backups are very important. Whereas a CU update is hardly exciting and dangerous, if anything goes wrong you want to be able to rollback. Just in case Microsoft, this script or maybe even you made a tiny mistake. After all, we are all human. 

## Part 2 - The CU installation
 * Copy the 'Upgrade NAV CU package' files to a system you want to upgrade.
 * Open PowerShell ISE as Administrator.
 * Change the execution policy by executing the following two Cmdlets
 
 ``` PS
 Set-ExecutionPolicy -ExecutionPolicy Unrestricted
 Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted 
 ```
 
 * Open the files **Step 1 - Install NAV Platform Cumulative Update.ps1** on the local system.
 * Execute the script using the green play button or with the hotkey **F5**.
   The script will stop active services, processes and IIS application pools that are locking the NAV files.
   Multiple pop-ups may appear with the question to stop certain services/processes or application pools. 
 * If a pop-up asks to close applications: click yes to continue.
 * If all validations have passed, you will be asked if you want to continue with the upgrade, click yes.

The Cumulative Update installation on this machine is finished! All NAV components found have been upgraded. The components found and upgraded are displayed in a pop-up by the script. 

 * Repeat the above steps for each server and client machine you want to upgrade.

**Tip:**
The script will not start stopped services again. It is best to keep all services stopped until all application servers have been upgraded and the NAV databases have been converted. After the installation and database conversion you can start the services *manually*   or you can *restart the server*. If you are not sure which services to start again, it is best to restart the server. Or you can check the host output or log file from the PowerShell script to see which services are stopped by the script.

## Part 3 - The NAV database conversion
**Assumptions**: 
 * The scripts are already on the application server from part 2 and the CU is already installed.
 * There are no active sessions on the NAV database (on SQL level) anymore. 
*You can check the active sessions on the NAV database from the SQL Management Studio > Activity Monitor > Processes*

**Steps:**
 * Open PowerShell ISE as Administrator.
 * Open the file **Step 2 - Generate 'Upgrade NAV Databases'.ps1**.
 * Execute the script using the green play button or with the hotkey **F5**.
 The scrip will create a new file in the script root directory and open this script in a new tab in PowerShell ISE.

``` PS
# Example
Convert-NAVDatabase -DatabaseName 'NAV100Prod' -SQLDatabaseServer SQLServer\SQLInstance -ServerInstance 'DynamicsNAV100' -NavRelease 2017 
Convert-NAVDatabase -DatabaseName 'NAV100Test' -SQLDatabaseServer SQLServer\SQLInstance -ServerInstance 'DynamicsNAV100Test' -NavRelease 2017 
```

 * Select one row with the NAV database you want to upgrade.
 * Execute this line with the run selection button or with the hotkey **F8**.
 * Repeat this step for each NAV database you want to upgrade.

The NAV database conversion is finished! 

**Note:** Converting a NAV database is an irreversible action. Going back requires a backup from the database.

## Part 4 - Start NAV environment and test the results
Start the NAV environment again. Easiest option is to restart the NAV application servers. Starting the NST services and IIS application pools manually is also an option, of course.

After that. You know..... open the NAV clients and click around for a bit. Check the build number. Have a beer to celebrate. Or work like crazy until sunrise to fix any problem you encounter. The usual...
