@ECHO OFF

rem Displays some ascii art, waits for user input to continue script
mode con:cols=80 lines=40 rem changes window size
cd %~dp0
type %~dp0hcs.txt
echo ================================================================================
type %~dp0title.txt
echo ================================================================================
echo                                 Press any key
echo ================================================================================
pause > nul
cls

rem  Checks if script was launched in administrator, and prompts user to relaunch if not

echo Administrative permissions required. Detecting permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: Current permissions inadequate.
    
    echo Right click script and launch as administrator
    pause >nul
    exit
)



rem Checks for an internet connection, and prompts user to connect ethernet if wifi isn't working/available
echo Connecting to HCS Internet
netsh wlan add profile filename=%~dp0\myProfile.xml
:netcheck
ping 8.8.8.8 -n 1 -w 1000 > nul
if %errorlevel% == 0 (
  echo Internet connection is available
) else (
  echo Internet connection is not available, connect ethernet before continuing
  timeout /t 5 /nobreak
  goto :netcheck
  
)

rem Here is where the actual service begins
echo Starting Service
pause > nul

rem  Check if Malwarebytes is installed by seeing if a start menu shortcut exists
if exist "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Malwarebytes.lnk" (
  echo Malwarebytes shortcut found. Opening...
  set /A mwbinstalled=1
  start "" "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe"
) else (
  echo Shortcut not found. Installing Malwarebytes now
  rem installs chocolatey and uses it to silently install malwarebytes and the pswinupdate package to automate updates
  rem launches in a new minimised powershell window so the rest of the script can run while malwarebytes is installing
  start /min /wait Powershell.exe -executionpolicy remotesigned -File %~dp0mwbchoco.ps1"
)
start %~dp0taskbar.bat

rem runs powershell script that lists the specs of the pc
Powershell.exe -executionpolicy remotesigned -File %~dp0\specs1.ps1"
pause >nul


rem There is no way to do this with batch scripting or powershell, so you have to change the switch manually 
echo "Opening settings to disable windows animations"
rem This setting changed location in windows 11, so heres a check so the shortcut goes to the correct place
ver | find "10." > nul
if %errorlevel% == 0 (
  echo Running on Windows 10
  echo opening Ease of Access settings to disable animations
  start ms-settings:easeofaccess-display
  
) else (
  ver | find "11." > nul
  if %errorlevel% == 0 (
    echo Running on Windows 11, opening Viusal effects settings to disable animations
    start ms-settings:easeofaccess-visualeffects
    pause >nul
  ) else (
    echo Not running on Windows 10 or 11
  )
)
pause >nul
taskkill /F /IM systemsettings.exe 	rem this force closes the settings window opened by the previous step


echo "Opening windows defender"		 
start windowsdefender:				rem the windows defender step cannot be automated, 
pause >nul							rem it needs a human to check everything is fine and to take action if not 
taskkill /F /IM sechealthui.exe		rem this force closes windows defender opened by the previous step


echo "disable startup items"						
start %windir%\system32\Taskmgr.exe /7 /startup			rem same as above, it needs a person to make a judgement on what startup items to disable
pause >nul
taskkill /F /IM taskmgr.exe								rem kills task manager on user input




echo Running Ccleaner Portable 
start "" %~dp0\ccleaner\ccleaner64.exe
pause >nul
cls
PowerShell.exe -ExecutionPolicy Bypass -File %~dp0downloads.ps1 rem runs powershell script that prompts user to delete 
cls																rem all executables in downloads folder 

rem Asks user if they want to install Teamview Remote Support, and if not

set /P c=Install HCS Remote[Y/N]? 
if /I "%c%" EQU "Y" goto :HCS
if /I "%c%" EQU "N" goto :restore


:restore
echo Enabling System Restore
powershell -command Enable-ComputerRestore -Drive "C:"
echo Creating restore point
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "HCS", 100, 7 > nul
echo Restore Point created successfully
choco uninstall malwarebytes
echo Uninstalling Malwarebytes using Chocolatey-cli
goto :exiting

:exiting
pause >nul
echo thanks for using!
echo Last service completed at: %date% %time% > C:\HCSLog.txt
start ms-settings:windowsupdate
exit


:HCS

PowerShell.exe -ExecutionPolicy Bypass -File %~dp0autoinstall.ps1"

goto :restore