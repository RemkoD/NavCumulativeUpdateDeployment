# Automated Dynamics NAV Cumulative Update Deployment
This project contains the PowerShell module 'NavCumulativeUpdateDeployment' and documentation with example scripts to automate NAV Cumulative Update (CU) platform deployment on server and client machines. 

### The PowerShell module 'NavCumulativeUpdateDeployment'
The module itself consists of a selection of useful functions joined together in one module to automate the CU deployment. The true power of the module is visible in the example scripts. 

### Example scripts: Deploy cumulative update 
There are two example scripts. The first one is used to deploy the CU. This script basically scans the host system for installed NAV components, takes the CU patch and makes sure the patch is installed properly on all NAV components found. After the installation you can start the second example script to convert the NAV database with just a few clicks.

**Main features of script 'Step 1':**
* Scans host for installed NAV components (Windows Registry scan).
* Stops known blocking services/processes (NST's, clients, MS Office, Application Pools, etc).
* Verifies if the files to be updated are writable (stops if certain files are still locked)
* Creates a backup of the folders before updating.
* Updates the files in the NAV component folders with the new CU files.
* Updates the default NST CustomSettings.config with the new available keys.
* Updates Windows Registry with the new NAV build number.

**Main features of script 'Step 2':**
 * Scans the local system for uniquely configured NAV databases from the NAV Service Tier configuration
 * Creates example Cmdlets with prefilled variables to convert the found NAV databases.
 * Saves the examples to a file and opens it in a new PowerShell ISE tab. 

**Main features of script 'Step 3':**
***Note:** Step 3 is generated by executing step 2. Step 3 is not included as file in this project.*
 * Loads the 'Microsoft.Dynamics.Nav.Model.Tools.psd1' module dynamically
 * Invokes the NAV database conversion
 * Invokes the schema synchronization to complete database conversion
 * Restarts NST between steps

Before using the example scripts, you need to create the Cumulative Update patch and put the example scripts on the right places. **[01 How to prepare a deployment package.md]** will help you to do this. 

## Choosing the right deployment strategy
Microsoft describes three options to deploy a Cumulative Update.
* Remove NAV installation and reinstall with a NAV DVD on a higher CU
* Use Click Once (Windows RTC and Web Client only)
* Manual patching servers and clients

### Alternative option
In an ideal situation servers are not installed, updated and managed manually. Installation and configuration changes can be carried out with PowerShell scripts. Together, the scripts allow you to generate a new server. This has multiple advantages. One of them being that you can generate a new server using a new NAV DVD. This way you do not need to upgrade a NAV installation with a higher CU, you simply generate a new server with the new NAV CU. Using Docker is an example of this. 

### Use case for this project
Most NAV installations are still on-premises on manually managed servers with very different environmental characteristics (Windows versions, installed NAV components, environment software, configurations). For this use case I have developed the module NavCumulativeUpdateDeployment. It uses the manual patching method in an automated and more perfected manner. It doesn't require much knowledge of the environment you are upgrading. The scripts detect and update NAV components on the fly. 
## Getting Started
* Download the project content to your local system
* Create a deployment package *(read: [documentation\01 How to prepare a deployment package.md])*
* Upgrade NAV applications server(s) and convert NAV databases *(read: [documentation\02 How to install CU.md])*

### Prerequisites
* PowerShell 3.0 or higher
* An already installed Microsoft Dynamics NAV environment (2013 or higher) you want to update with a higher Cumulative Update.

On Windows 8 and Windows Server 2012 and higher PowerShell 3.0 (or higher) is installed by default. On Windows 7 systems and Windows Server 2008 R2 you probably need to update the [Windows Management Framework] to get PowerShell 3.0 or higher. 

### NAV compatible versions
* Theoretically working for **NAV 2013** to **NAV 2017**
* Tested and proven on **NAV 2016** and **NAV 2017**
* Not yet tested on **NAV 2018**, take caution.

## Contributing
All contributions, feedback or suggestions are welcome.

## Support
There is no official support available for this tool. Support is provided on a voluntary basis.
 * Issues on [Github]
 * [Thread on the Mibuso forum]

## Authors
**[Remko Dannenberg]** ([4PS])

## License
This project is licensed under the GPLv3 License - see the [LICENSE] file for details.

## Disclaimer
This program is distributed "AS IS" in the hope that it will prove useful, but WITHOUT ANY WARRANTY; without even the implied warranty of merchantability or fitness for a particular purpose.  

## Acknowledgments
* My employer [4PS] for making time available to work on this project
* Edwin Keukens - [4PS] employee - *(Helping with the NAV data conversion part)*
* [Jorge Alberto Torres] - Microsoft employee - *(For the [original post] on manual patching)*
* [Duilio Tacconi] - Microsoft employee - *(for the [update] on the manual patching post)*
* [Guys in this thread] *(for testing files on locks)*
* Jason Wasser *(for the logging module)*

[Thread on the Mibuso forum]: <https://forum.mibuso.com/discussion/72044/tool-powershell-module-to-create-and-deploy-nav-cu-patches#latest>
[Github]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment>
[Windows Management Framework]: <https://www.microsoft.com/en-us/download/details.aspx?id=54616>
[Guys in this thread]: <https://social.technet.microsoft.com/Forums/windowsserver/en-US/74ea3752-9403-4296-ab98-d03fcc12b608/how-to-check-to-see-if-a-file-is-openlocked-before-trying-to-copy-it?forum=winserverpowershell>
[01 How to prepare a deployment package.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/01%20How%20to%20prepare%20a%20deployment%20package.md>
[documentation\01 How to prepare a deployment package.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/01%20How%20to%20prepare%20a%20deployment%20package.md>
[documentation\02 How to install CU.md]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/Documentation/02 How to install CU.md>	
[Remko Dannenberg]: <https://www.linkedin.com/in/remko-dannenberg-0a34541b/>
[LICENSE]: <https://github.com/RemkoD/NavCumulativeUpdateDeployment/blob/master/LICENSE>
[4PS]:<https://www.4ps.eu/>
[original post]:<https://blogs.msdn.microsoft.com/nav/2014/11/13/how-to-get-back-the-hotfix-directories-from-nav-2015-cumulative-update-1/>
[Jorge Alberto Torres]:<https://social.msdn.microsoft.com/profile/Jorge+Alberto+Torres+%5BMSFT%5D>
[Duilio Tacconi]: <https://www.linkedin.com/in/duilio-tacconi-4042999a/>
[update]: <https://blogs.msdn.microsoft.com/nav/2018/02/19/how-to-generate-the-hotfix-directories-from-microsoft-dynamics-nav/>
