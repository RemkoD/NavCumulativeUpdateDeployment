### What is a CU deployment package
A set of files needed to install a new Dynamics NAV Cumulative Update on a client or server machine. It contains the NAV files stripped from a NAV product DVD and PowerShell scripts to install the files on the machine where the scripts are executed. 

### When do you create a new package?
When you want to deploy a new Dynamics NAV Cumulative Update on multiple server and/or client machines. Setting up a package is a onetime task for each CU you are going to install. After making the package the deployment of the CU on a machine is only a few clicks. 

### How to create a deployment package
 * Download the desired Dynamics NAV Cumulative Update from Microsoft: [NAV2016], [NAV2017], [NAV2018]

 * Extract the NAV product DVD from the download. 
 	* Example: Copy the content from CU 20 NAV 2017 W1.zip -> NAV.10.0.23021.W1.DVD.zip into ***C:\Temp\NAV 2017 CU20 DVD***.

 * Download PowerShell module NavCumulativeUpdateDeployment from Github
 	* Go to: https://github.com/RemkoD/NavCumulativeUpdateDeployment
	* Download: Click the ***clone or download*** button. 
	* Extract the file to ***C:\Temp\NavCumulativeUpdateDeployment***

 * Create a new directory for your new CU deployment package.
 ``` PS
 New-Item -ItemType directory -Path "C:\Temp\Upgrade NAV CU package"
 ```
 
 * Create the CU patch
 You can use the PowerShell Cmdlet *Create-CumulativeUpdateFilesFromDvd* from the *NavCumulativeUpdateDeployment* module for this.
 
``` PS
# Import the NavCumulativeUpdateDeployment module
Import-Module "C:\Temp\NavCumulativeUpdateDeployment\Module\NavCumulativeUpdateDeployment.psm1" -DisableNameChecking -Force

# Extract the NAV files from the NAV DVD. 
Create-CumulativeUpdateFilesFromDvd -DvdDirectory "C:\Temp\NAV 2017 CU20 DVD" -BatchDirectory "C:\Temp\Upgrade NAV CU package\Cumulative Updates\NAV2017_W1_CU20_Build_10.0.23021.0"  -Verbose

# Note: Change the BatchDirectory folder name 'NAV2017_W1_CU20_Build_10.0.23021.0' to your specific situation.
# Example: If you use a NAV 2018 Dutch CU7 DVD the folder should be named 'NAV2018_NL_CU07_Build_11.0.23019.0'

```

 * Copy the upgrade scripts into the patch folder
``` PS
Move-Item -Path "C:\Temp\NavCumulativeUpdateDeployment\Module" -Destination "C:\Temp\Upgrade NAV CU package"
Move-Item -Path "C:\Temp\NavCumulativeUpdateDeployment\Examples\*" -Destination "C:\Temp\Upgrade NAV CU package"
```

* Modify *'Load Deployment Settings.ps1'* from *"C:\Temp\Upgrade NAV CU package\Load Deployment Settings.ps1"* to your needs.
  The following variables are necessary to set, the other variables can be left default for now.

``` PS
# Example 1 (NAV2017 CU20 with Dutch localization)
$NavVersion = '2017'
$CumulativeUpdate = '10.0.23021.0'
$Localisation = "NL" 

# Example 2 (NAV2018 CU20 no localization)
$NavVersion = '2018'
$CumulativeUpdate = '11.0.23019.0'
$Localisation = "W1" 
```

That's it! you've created a CU deployment package. Ready to upgrade any system containing any NAV Component *(for the specific localization)*. 

[NAV2016]: <https://support.microsoft.com/en-us/help/3108728/released-cumulative-updates-for-microsoft-dynamics-nav-2016>
[NAV2017]: <https://support.microsoft.com/en-us/help/3210255/released-cumulative-updates-for-microsoft-dynamics-nav-2017>
[NAV2018]: <https://support.microsoft.com/en-us/help/4072483/released-cumulative-updates-for-microsoft-dynamics-nav-2018>
