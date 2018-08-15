<###                                                                                          ,  ,
                                                                                             / \/ \
                                                                                            (/ //_ \_
     .-._           _                                                                        \||  .  \
      \  '-._      (@)                                                                 _,:__.-"/---\_ \
 ______/___  '.    |-|----------------------------------------------------------------'~-'--.)__( , )\ \
`'--.___  _\  /    | |    ___                                       _____               _  ,'    \)|\|`\|
     /_.-' _\ \ _:,_ |   |   \   _ _   __ _   __ _   ___   _ _     |_   _|  ___   ___  | |  ___  " |||  (
   .'__ _.' \'-/,`-~`|   | |) | | '_| / _` | / _` | / _ \ | ' \      | |   / _ \ / _ \ | | (_-<    |/|
       '. ___.> /=,| |   |___/  |_|   \__,_| \__, | \___/ |_||_|     |_|   \___/ \___/ |_| /__/    | |
        / .-'/_ )  | |                       |___/                                                 | |
        )'  ( /(/  |_|_____________________________________________________________________________|_|
             \\ "  (@)                                                                             (@)
              '==' 

###>

[array] $CmdLets = @(
	'Convert-NavDatabase.ps1'
	'Convert-NavDatabases.ps1',
	'Create-CumulativeUpdateFilesFromDvd.ps1',
	'Get-DatabaseversionnoBySqlcmd.ps1',
	'Get-DistinctNavDatabases.ps1',
	'Get-NavComponent.ps1',
	'Get-NavHelpInstance.ps1',
	'Get-NavManagementModule.ps1',
	'Get-NavModelToolsModule.ps1',
	'Get-NavVersionFolder.ps1',
	'Get-NavWebServerInstance.ps1',
	'Show-MessageBox.ps1',
	'Stop-LocalNavEnvironment.ps1',
	'Test-FilesLock.ps1',
	'Update-WinRegNavBuild.ps1',
	'Write-Log.ps1'
)

$Dir = (Join-Path -Path $PSScriptRoot -ChildPath 'Functions')

foreach ($CmdLet in $CmdLets) {

	. (Join-Path -Path $Dir -ChildPath $CmdLet)
}

