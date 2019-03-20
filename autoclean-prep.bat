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
title CleanTech - Prep Stage

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

echo Adding to Startup...
echo Command running: copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"
copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"

if not exist %tac_workingdir%\CT-Flags.txt goto initvars

if exist C:\CleanTechTemp\CT-Flags.txt (
	echo Printing Last run variables:
	for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do echo %%i
	for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do set %%i
	)
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
	set tac_clientdir=
	set tac_>%tac_workingdir%\CT-Flags.txt

rem	if defined %tac_lastname% (set "tac_tac_debugmode=pause" & set "tac_tac_debugmode=pause") else (goto:drivelettertest)

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
	echo Incorrect input. & goto clientnameconfirm

:clientnamegood
goto passquestion

::	set autoadminlogonenabled=0
::	reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon | find "1"
::	if %ERRORLEVEL% EQU 0 (set autoadminlogonenabled=1 & echo autoadminlogonenabled=!autoadminlogonenabled! & goto av) || goto av REM skipping autologin prompts
::	pause

:passquestion
	set password=
	set passq=
	set /p passq="Does the the current user (%USERNAME%) require a password? (y/n): "
	if /i %passq%==y goto passwordneeded
	if /i %passq%==n goto drivelettertest
	echo Incorrect input. & goto passquestion

:passwordneeded
	set /p password="Please enter the password for %USERNAME%: "
	if /i %password%=="" echo You didn't enter anything! *Sigh* Try again... & goto passwordneeded

	:passconfirm
	echo You entered: %password%
	set passconfirm=
	set /p passconfirm="Is this correct? (y/n): "

	if /i %passconfirm%==y goto passcorrect
	if /i %passconfirm%==n goto passwordneeded
	echo Incorrect input. & goto passconfirm
	:passcorrect
:: --- END client_info_entry.bat

:: --- START map_beast.bat
:beastmap
	set tac_step=beastmap
	set tac_>%tac_workingdir%\CT-Flags.txt

	:drivelettertest
		for %%d in (t u v w x y z) do (if not exist %%d: echo Beast Utilities folder will be mapped to: %%d: & set "tac_netletter=%%d:" & echo, & goto netmap)

		if tac_offline==y goto cleanupfilesprep

	:netmap
		echo Mapping Beast Utilities folder to drive letter %tac_netletter%
		echo,

		echo Command running: net use %tac_netletter% \\TechTutors-1\Utilities /user:techtutors *
		net use %tac_netletter% \\TechTutors-1\Utilities /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto netmap
		echo,

		color 1f
		echo Network drive mapped to %tac_netletter%
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
	echo Command running: robocopy "%tac_netletter%\Clean Up" "%tac_workingdir%" /XD "*.sync" /s
	robocopy "%tac_netletter%\Clean Up" "%tac_workingdir%" /XD "*.sync" /s

	echo Command running: mkdir "%tac_clientdir%"
	mkdir "%tac_clientdir%"
	echo,

	:disableav
	color 4f
	echo IMPORTANT	
	echo -----------------------------------------------------------------------
	echo Please check for running av and disable real-time features temporarily.
	echo You'll need to ensure that it will be in passive mode throughout reboots.
	echo Press any key when you've finished to continue.
	echo -----------------------------------------------------------------------
	echo Command running: "%tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	call "%tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	%tac_debugmode%
:: --- END cleanupfilesprep.bat

:: --- START reg_backup.bat
:registrybackup
	set tac_step=registrybackup
	set tac_>%tac_workingdir%\CT-Flags.txt

	color 1f

	:maxwindow
		"%tac_workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Prep Stage"

		reg export "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" "%tac_clientdir%\PreClean-SystemRestore.reg"

	:uacbackup

		echo Saving current UAC values

		REM safety code incase we aprubtly closed or crashed... Don't want to overwrite client's original registry entries
		IF EXIST "%tac_clientdir%\Preclean-Policies_System.reg" goto uac-reg

	:policies-system
		REG EXPORT HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System "%tac_clientdir%\Preclean-Policies_System.reg"
		echo,
	    
	:autologon
	    echo Saving current AutoLogon values
	    IF EXIST "%tac_clientdir%\Preclean-Winlogon.reg" goto autologoncheck
	    echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

	    %tac_debugmode%

	    echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\Preclean-Winlogon.reg"
	    REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\Preclean-Winlogon.reg"
	    echo,

	    %tac_debugmode%
:: --- END reg_backup.bat

:: --- START reg_prepmode_changes.bat
:regchanges
set tac_step=regchanges
set tac_>%tac_workingdir%\CT-Flags.txt

:uac-reg
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
set tac_step=createttadmin
set tac_>%tac_workingdir%\CT-Flags.txt

:: Creating Tech Tutors admin accout to avoid PIN-based autologin issues and ot aid in recovery in case things go cataclysmic
echo net user /add techtutors
net user /add techtutors
echo net localgroup administrators /add techtutors
net localgroup administrators /add techtutors
:: --- END techtutors_admin_account_create.bat

	REM :autologoncheck
    REM	if /i %autoadminlogonenabled%==1 goto systeminfo

REM skipping due to current bugs	    :setautologin
rem		    echo Setting autologin for CleanTech session...
rem		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d %USERNAME% /f
REM		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d %PASSWORD% /f
REM		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
REM		    echo,

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

	echo Importing perfmon xml...
	echo logman import -n CleanTech-PreCleanTest -xml Perfmon-Pre.xml
	echo,
	logman import -n CleanTech-PreCleanTest -xml Perfmon-Pre.xml

    echo Starting Performance Monitor. Please wait...
	echo,
	
	echo Command running: logman start CleanTech-PreCleanTest
	logman start CleanTech-PreCleanTest

	echo Waiting for perfmon to finish...
    echo timeout 660
	timeout 660
	color E0 & %tac_debugmode% & color 1f

:nextstageprep
	echo Adding flags to text file
	set tac_>%tac_workingdir%\CT-Flags.txt

	:: NOTE: Need to check how to automatically log the number that gets presented in the BootTimer dialogue. (Does it output to STDERR?)

	:: --- START boottimer_1-1_pre.bat
:boottimer
	set tac_step=boottimer
	set tac_>%tac_workingdir%\CT-

	echo Starting BootTimer. Prepare for reboot...
	echo Command running: "%tac_workingdir%\boottimer.exe"
	echo,
	start %tac_workingdir%\boottimer.exe
	echo press any key when you're ready for stage 2
	pause,

:prepdone
	set tac_step=prepdone
	set tac_stage=startclean
	set tac_>%tac_workingdir%\CT-Flags.txt
	:: %tac_workingdir%\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes <-- NOT WORKING?!?
	shutdown /r /t 0
	:: --- END boottimer_1-1_pre.bat
