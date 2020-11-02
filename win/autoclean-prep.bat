@echo off
:: TIM
:: ------------------
:: AUTOCLEAN-PREP.BAT
:: ------------------

:: Crappy to do list follows...
:: Look into Task Manager vs. StartupTool (Nirsoft) - REQ from Will
:: SYSTEM BEEP AT TIMES OF INPUT
:: add test for null entries
:: add test for network connectivity (NIC working & BEAST accessible)
:: Should log start time of each script (really, of each command)
::     - Observe logwithdate batch file to see how vocatus accomplishes this
:: Add test / install for .NET Framework 3.5 (Keep in mind Win 7/8/8.1/10)

:: BatchGotAdmin 
:-------------------------------------
::  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
    
:windowprep
SETLOCAL EnableDelayedExpansion
color 1f
mode 100,35
title %COMPUTERNAME%: CleanTech - Prep Stage

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

echo %horiz_line%
echo CleanTech - Prep Stage
echo %horiz_line%
echo,

set tac_workingdir=C:\CleanTechTemp

:winvertest
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" set tac_winver=Win10
	if "%version%" == "6.3" set tac_winver=Win8.1
	if "%version%" == "6.2" set tac_winver=Win8
	if "%version%" == "6.1" set tac_winver=Win7
	if "%version%" == "6.0" set tac_winver=WinVista

echo Adding autologon scripts to Startup...
echo Command running: copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"
copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"

if not exist %tac_workingdir%\CT-Flags.txt goto initvars

if exist C:\CleanTechTemp\CT-Flags.txt (
	echo Printing Last run variables:
	for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do echo %%i
	for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do set %%i
	)

::Test to see if this script has already been called and completed.
::prepdone test
if not !tac_step!==prepdone (
	echo Resuming from step:!tac_step!
	pause
	goto !tac_step!
	) else (
	color 4f
	echo,
	echo It appears that you've already completed this step.
	echo Please relaunch from autoclean-launcher.bat.
	echo If you think you are seeing this in error
	echo please contact tech support. :P
	echo Press a key to exit...
	echo,
	pause
	exit
	)
)

:initvars
	set tac_stage=prep
	set tac_step=initvars
	set tac_netletter=
	set tac_lastname=
	set tac_firstname=
	set tac_tac_debugmode=rem
	set tac_offline=no
	set tac_perfmondir=C:\CT-Perfmon
	set tac_clientdir=
	set tac_cleanup_srcdir=
	set tac_usbdir=
	set tac_cleanup_logs=
	set tac_>%tac_workingdir%\CT-Flags.txt

rem	if defined %tac_lastname% (set "tac_tac_debugmode=pause" & set "tac_tac_debugmode=pause") else (goto:drivelettertest)

:: For future usage. Hoping to intelligently add an offline mode using the FAHT sticks that will sync with the Beast when plugged in.

:::tac_offlineset
::set tac_offline=
::set /p tac_offline="Would you like to work tac_offline? (y/n]) "
::	if /i %tac_offline%==y (set "tac_offline=yes" & goto clientinfo)
::	if /i %tac_offline%==n (set "tac_offline=no" & goto drivelettertest)
::	echo Incorrect input. & goto tac_offlineset

:: Set date variable
for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
    IF NOT "%%~f"=="" (
        set /a tac_FormattedDate=10000 * %%f + 100 * %%d + %%a
        set tac_FormattedDate=!tac_FormattedDate:~-0,4!-!tac_FormattedDate:~-4,2!-!tac_FormattedDate:~-2,2!
    )
)

:: Turn off hibernation
:hibernateoff
powercfg /hibernate off

:offlinequestion
	set tac_step=offlineq
	set tac_>%tac_workingdir%\CT-Flags.txt

	set offlineq=
	set /p offlineq="Start in (no network) offline mode? (y/n): "
	if /i %offlineq%==y set tac_offline=yes && goto offlineprep
	if /i %offlineq%==n set tac_offline=no && goto clientinfo
	echo Incorrect input.
	goto offlinequestion

:offlineprep
	set tac_step=offlineprep
	set tac_>%tac_workingdir%\CT-Flags.txt
	set tac_usb=

	for /f %%i in ('wmic logicaldisk get deviceid^|findstr /R [a-z]:') do (
		if exist %%i\TTCleanUp (
			set tac_cleanup_srcdir=%%i\TTCleanUp
			set "tac_cleanup_logs=%systemdrive%\%homepath%\Desktop\CleanUpLogs\"
			set tac_usb=%%i
			if NOT EXIST %tac_cleanup_logs% (mkdir %tac_cleanup_logs%)
			)
		)

	if NOT DEFINED tac_usb (
		color 4f
		echo,
		echo Cannot find USB drive. Are you sure it is inserted?
		echo,
		echo Please insert USB drive with TTCleanUp in it and press a key to try again.
		pause
		goto offlineprep
		) else goto clientinfo

:clientinfo
set tac_step=clientinfo
set tac_>%tac_workingdir%\CT-Flags.txt
:: --- START client_info_entry.bat
color E0
echo ------------------------
echo Please enter client info
echo ------------------------
echo,

:clientname
	set input=
	set tac_firstname=
	set tac_lastname=
	set /p tac_firstname="Client's first name: "
	set /p tac_lastname="Client's Last name: "
	echo,

:clientnameconfirm
	set /p input="You entered: %tac_firstname% %tac_lastname%. Is this correct? (y/n): "
	rem %=%
	if /i %input%==y goto clientnamegood
	if /i %input%==n goto clientname
	echo Incorrect input.
	goto clientnameconfirm

:clientnamegood

:pinquestion
	set pinq=
	set /p pinq="Does the the current user (%USERNAME%) use a 4-6 digit PIN to login? (y/n): "
	if /i %pinq%==y goto autoadminlogontest
	if /i %pinq%==n goto passquestion
	echo Incorrect input.
	goto pinquestion

:passquestion
	set password=
	set passq=
	set /p passq="Does the the current user (%USERNAME%) require a password? (y/n): "
	if /i %passq%==y goto passwordneeded
	if /i %passq%==n goto nopass
	echo Incorrect input.
	goto passquestion

:passwordneeded
	set /p password="Please enter the password for user: %USERNAME%: "
	if /i %password%=="" echo You didn't enter anything! *Sigh* Try again... & goto passwordneeded

	:passconfirm
		echo You entered: %password%
		set passconfirm=
		set /p passconfirm="Is this correct? (y/n): "
		if /i %passconfirm%==y goto passcorrect
		if /i %passconfirm%==n goto passwordneeded
		echo Incorrect input. & goto passconfirm

:nopass
	set password

:passcorrect

:autoadminlogontest
	set tac_step=autoadminlogontest
	set tac_>%tac_workingdir%\CT-Flags.txt

	set tac_autoadminlogonenabled=
	reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon | find "1"
	if %ERRORLEVEL% EQU 0 (
		set tac_autoadminlogonenabled=1
		echo
		echo ----------------------------
		echo tac_autoadminlogonenabled=!tac_autoadminlogonenabled!
		echo ----------------------------
		echo
		goto beastmap
		)
:: --- END client_info_entry.bat

if tac_offline==yes (
	goto cleanupfilesprep
	) else (goto beastmap)

:: --- START map_beast.bat
:beastmap
	set tac_step=beastmap
	set tac_>%tac_workingdir%\CT-Flags.txt

	:drivelettertest
		for %%d in (t u v w x y z) do (if not exist %%d: echo Beast Utilities folder will be mapped to: %%d: & set "tac_netletter=%%d:" & echo, & goto netmap)

	:netmap
		echo Mapping Beast Utilities folder to drive letter %tac_netletter%
		echo,

		echo Command running: net use %tac_netletter% \\tt1\Utilities /user:techtutors *
		net use %tac_netletter% \\tt1\Utilities /p:no /user:techtutors * 
		if errorlevel 1 (
			cls
			color 4f
			echo That didn't seem to work. Pres any key to try again...
			pause
			color E0
			cls
			goto netmap
			)
		echo,

		color 1f
		echo Network drive mapped to %tac_netletter%
		set tac_cleanup_srcdir="%tac_netletter%\Clean Up"
		echo Clean Up files source: %tac_cleanup_srcdir
	:: --- END map_beast.bat

:: --- START cleanupfilesprep.bat
:cleanupfilesprep
	set tac_step=cleanupfilesprep
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo Creating local clean up subdirectories for %tac_firstname% %tac_lastname%
	echo,

	set "tac_workingdir=C:\CleanTechTemp"
	mkdir "%tac_workingdir%"
	echo cd "%tac_workingdir%"
	cd "%tac_workingdir$"
	set "tac_clientdir=%tac_workingdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"

	%tac_debugmode%

	echo Copying automation files to C:\CleanTechTemp
	echo,
	echo Command running: robocopy %tac_cleanup_srcdir% "%tac_workingdir%" /XD "*.sync" /s
	robocopy %tac_cleanup_srcdir% "%tac_workingdir%" /XD "*.sync" /s

	echo Command running: mkdir "%tac_clientdir%"
	mkdir "%tac_clientdir%"
	echo,

	:disableav
	color 4f
	echo IMPORTANT	
	echo -------------------------------------------------------------------------
	echo Please check for running av and disable real-time features temporarily.
	echo You'll need to ensure that it will be in passive mode throughout reboots.
	echo,
	echo Press any key to start SecuritySoftview for a list of active AV and
	echo Firewalls.
	echo,
	echo Once you're done deactivating any AV, close SecuritySoftView
	echo to continue the scripts.
	echo -------------------------------------------------------------------------
	pause
	echo Command running: "%tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	call "%tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	%tac_debugmode%
:: --- END cleanupfilesprep.bat

:: --- START reg_backup.bat
:registrybackup
	set tac_step=registrybackup
	set tac_>%tac_workingdir%\CT-Flags.txt

	color 1f

	:wshreg
		reg export "HKLM\Software\Microsoft\Windows Script Host\Settings" "%tac_clientdir%\PreClean-WSH.reg"

	:maxwindow
		"%tac_workingdir%\nircmd\nircmd.exe" win max ititle %COMPUTERNAME%: "CleanTech - Prep Stage"

		reg export "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" "%tac_clientdir%\PreClean-SystemRestore.reg"

	:uacbackup
		echo Saving current UAC values

		REM safety code incase we abruptly closed or crashed... Don't want to overwrite client's original registry entries
		IF EXIST "%tac_clientdir%\Preclean-Policies_System.reg" goto policies-saved

	:policies-system
		REG EXPORT HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System "%tac_clientdir%\Preclean-Policies_System.reg"
		echo,

	:policies-saved
	    
	:autologon
	    echo Saving current AutoLogon values
	    IF EXIST "%tac_clientdir%\Preclean-Winlogon.reg" goto autologon-saved
	    echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

	    %tac_debugmode%

	    echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\Preclean-Winlogon.reg"
	    REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\Preclean-Winlogon.reg"
	    echo,
    :autologon-saved

	    %tac_debugmode%
:: --- END reg_backup.bat

:: --- START reg_prepmode_changes.bat
:regchanges
	set tac_step=regchanges
	set tac_>%tac_workingdir%\CT-Flags.txt

:wshregchange
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 1 /f

:uac-reg
	echo,
    echo Turning off UAC temporarily...
    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    echo,

:restorepoint
	echo Creating Pre-Clean restore point...
	reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /t reg_dword /v SystemRestorePointCreationFrequency /d 0 /f >nul 2>&1
	powershell "Enable-ComputerRestore -Drive "%SystemDrive%""
	powershell "Checkpoint-Computer -Description 'CleanTech: Pre-Clean checkpoint'"
	%tac_debugmode%
:: --- END reg_prepmode_changes.bat

:: --- START techtutors_admin_account_create.bat
:createttadmin
::Skip this for now
::	set tac_step=createttadmin
::	set tac_>%tac_workingdir%\CT-Flags.txt

	:: Creating Tech Tutors admin accout to avoid PIN-based autologin issues and ot aid in recovery in case things go cataclysmic
::	echo net user /add techtutors
::	net user /add techtutors
::	echo net localgroup administrators /add techtutors
::	net localgroup administrators /add techtutors
:: --- END techtutors_admin_account_create.bat

:setautologon
	IF "%tac_autoadminlogonenabled%" EQU 1 (goto chocoinstall)

	echo Setting autologin for CleanTech session...
	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d %USERNAME% /f
	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d %PASSWORD% /f
	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
	echo,

:chocoinstall
	set tac_step=chocoinstall
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo installing Chocolatey
     @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:systeminfo
	set tac_step=systeminfo
	set tac_>%tac_workingdir%\CT-Flags.txt
	
	echo Dumping preclean system info...
	echo Command running: msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-preclean-systeminfo-%tac_FormattedDate%.nfo"
	msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-preclean-systeminfo-%tac_FormattedDate%.nfo"
	echo,

	echo Pre-emptively rebuilding performance counters
	echo Command running: lodctr /r
	lodctr /r
	echo,

	echo Creating perfmon directory
	mkdir %tac_perfmondir%

	:perfmonimportpreclean
		echo Clearing any old CTPreclean settings
		echo logman delete -n CTPreclean
		logman delete -n CTPreclean
		echo logman delete -n CTPostclean
		logman delete -n CTPostclean
		echo,
		echo Importing perfmon xml...
		echo logman import -n CTPreclean -xml "%tac_workingdir%\Perfmon-Pre.xml"
		echo,

		logman import -n CTPreclean -xml "%tac_workingdir%\Perfmon-Pre.xml"

		if %errorlevel% EQU -2147467259 (
			echo,
			echo PreClean perfmon import SUCCESS!
			%tac_debugmode%
			goto perfmonimportpostclean
			)

		if %errorlevel% NEQ 0 (
		echo not ready...
		timeout 5
		goto perfmonimportpreclean
		)
		echo,
		echo PreClean perfmon import SUCCESS!

	:perfmonimportpostclean
		echo Importing perfmon xml...
		echo logman import -n CTPostclean -xml "%tac_workingdir%\Perfmon-Post.xml"
		echo,

		logman import -n CTPostclean -xml "%tac_workingdir%\Perfmon-Post.xml"

		if %errorlevel% EQU -2147467259 (
			echo,
			echo PreClean perfmon import SUCCESS!
			%tac_debugmode%
			goto perfmontest
			)

		if %errorlevel% NEQ 0 (
		echo not ready...
		timeout 5
		goto perfmonimportpostclean
		)
		echo,
		echo PostClean perfmon import SUCCESS!

	:perfmontest
	    echo Starting Performance Monitor. Please wait...
		echo,
		
		echo Command running: logman start CTPreclean
		logman start CTPreclean

		echo Waiting for perfmon to finish...
	    echo timeout 660
		timeout 660

	color E0
	%tac_debugmode%
	color 1f

:nextstageprep
	echo Adding flags to text file
	set tac_>%tac_workingdir%\CT-Flags.txt

	:: NOTE: Need to check how to automatically log the number that gets presented in the BootTimer dialogue. (Does it output to STDERR?)

:prepdone
	set tac_step=prepdone
	set tac_stage=startclean
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo Starting BootTimer. Prepare for reboot...
	echo Command running: "%tac_workingdir%\boottimer.exe"
	echo,
	
	start %tac_workingdir%\boottimer.exe
	echo Rebooting in 10 seconds...
	timeout 10	
	
	shutdown /r /t 0
	:: --- END boottimer_1-1_pre.bat ???
