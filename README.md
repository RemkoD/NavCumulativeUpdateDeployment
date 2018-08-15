# Automated Dynamics NAV Cumulative Update Deployment
This projects contains the PowerShell module 'NavCumulativeUpdateDeployment' and documentation with example scripts to automate NAV Cumulative Update (CU) platfrom deployment on server and client machines. 

### The PowerShell module 'NavCumulativeUpdateDeployment'
The module itself is just bunch of handy functions packed together in one module to automate the CU deployment. The true power of the module is visible in the example scripts. 

### Example scripts: Deploy cumulative update 
These scripts are the true power of this project. Basically what it does: It scans the host system on installed NAV components, takes the CU patch and makes sure the patch is installed proper on all found NAV components. After the installation you can start the NAV database conversion with just a few clicks.

**Main features of script 'Step 1':**
* Scans host on installed NAV components (Windows Registery scan).
* Stops known blokking services/processes (NST's, clients, MS Office, Application Pools, etc).
* Validates if all targeted files to update are writeable (stops when some files are still locked)
* Creates a backup from the folders before updating.
* Update the files in the NAV component folders with the new CU files.
* Updates the default NST CustomSettings.config with the new available keys.
* Updates Windows Registery with the new NAV build number.

**Main features of script 'Step 2':**
 * Scans the local system on unique configured NAV databases from the NAV Service Tier configuration
 * Creates example Cmdlets with prefilled variables to convert the found NAV databases.
 * Saves the examples to a file and opens it in a new PowerShell ISE tab. 

**Main features of script 'Step 3':**
***Note:** Step 3 is generated by executing step 2. Step 3 is not included as file in this project.*
 * Loads the 'Microsoft.Dynamics.Nav.Model.Tools.psd1' module dynamically
 * Invokes the NAV database conversion
 * Invokes the schema synchronization to complete database conversion
 * Restart NST between steps

Before you can go wild with the example scripts, you need to make the Cumulative Update patch and put the example scripts on the rights place. **[01 How to prepare a deployment package.md]** will help you to do exactly that. 

## Choosing the right deployment strategy
Microsoft describes basically three options to deploy a Cumulative Update.
* Remove NAV installation and reinstall with a NAV DVD on a higher CU
* Use ClickOnce (Windows RTC and Web Client only)
* Manual patching servers and clients

### Additional alternative
In an ideal situation servers are not installed, updated and managed manually. Installations and configuration changes can be done with PowerShell scripts. The scripts together make it possible to generate a new server. This has multiple advantages. One of them is that you can generate a new server using a new NAV DVD. This way you do not need to upgrade a NAV installation with a higher CU, you simply generate a new server with the new NAV CU.

### Usecase for this project
Most NAV installations are still on-premises on manually managed servers with wild diverse environmental characteristics (Windows versions, installed NAV components, environment software, configurations). For this usecase I've developed the module NavCumulativeUpdateDeployment. It uses the manual patching method in an automated and more perfected manner. It doesn't require much knowledge of the envirnoment you're upgrading. The scripts detects and updates NAV components on the fly. 

## Getting Started
* Download the project content to your local system
* Create a deployment package *(read: [documentation\01 How to prepare a deployment package.md])*
* Upgrade NAV applications server(s) and convert NAV databases *(read: [documentation\02 How to install CU.md])*

### Prerequisites
* PowerShell 3.0 or higher
* Installation of Dynamics NAV 2013 or higher you want to update with a higher Cumulative Update

On Windows 8 and Windows Server 2012 and higher PowerShell 3.0 (or higher) is default installed. On Windows 7 systems and Windows Server 2008 R2 you probably need to update the [Windows Management Framework] to get PowerShell 3.0 or later. 

## Contributing
Any contribution, feedback or suggestion is welcome.

## Support
There is no offical support on this tool. Any support is voluntarily.
 * Issues on [Github]
 * [Thread on the Mibuso forum]

## Authors
**[Remko Dannenberg]** (4PS)

Copyright © 2018 [4PS B.V.]

## License
This project is licensed under the GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details.

## Disclaimer
This program is distributed "AS IS" in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of merchantability or fitness for a particular purpose.  

## Acknowledgments
* My employer 4PS for making time available to work on this project
* Edwin Keukens - 4PS employee - *(Helping with the NAV data conversion part)*
* Jorge Alberto Torres - Microsoft employee - *(For the original post on manual patching)*
* [Guys in this thread] *(for testing files on locks)*
* Jason Wasser *(for the logging module)*

[Thread on the Mibuso forum]: <https://forum.mibuso.com/discussion/71232/deployment-strategy-for-cumulative-platform-updates#latest>
[Github]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment>
[Windows Management Framework]: <https://www.microsoft.com/en-us/download/details.aspx?id=54616>
[Guys in this thread]: https://social.technet.microsoft.com/Forums/windowsserver/en-US/74ea3752-9403-4296-ab98-d03fcc12b608/how-to-check-to-see-if-a-file-is-openlocked-before-trying-to-copy-it?forum=winserverpowershell
[01 How to prepare a deployment package.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/01%20How%20to%20prepare%20a%20deployment%20package.md>
[documentation\01 How to prepare a deployment package.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/01%20How%20to%20prepare%20a%20deployment%20package.md>
[documentation\02 How to install CU.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/02 How to install CU.md>
[Remko Dannenberg]: <https://www.linkedin.com/in/remko-dannenberg-0a34541b/>
[LICENSE.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/LICENSE>
[4PS B.V.]: <https://www.4ps.nl/>
