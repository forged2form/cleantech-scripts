
:: --------------------------
:: AUTOCLEAN-REALLYFINISH.BAT
:: --------------------------

@echo off
color 4f
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

color 1f
mode 100,35
title CleanTech - Really Finish

SETLOCAL EnableDelayedExpansion

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

echo %horiz_line%
echo CleanTech - Wrap Up
echo %horiz_line%
echo,

set "workingdir=C:\CleanTechTemp"
echo cd "%workingdir%"
cd "%workingdir%"

echo Printing Last run variables:
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do echo %%i
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do set %%i

::reallyfinish done test
if !tac_step!==reallyfinishdone (
	color 4f
	echo,
	echo It appears that you've already completed this step.
	echo Please relaunch from autoclean-launcher.bat.
	echo If you think you are seeing this in error
	echo please contact tech support. :P
	echo Press a key to exit...
	echo,
	pause
	exist
)

if NOT !tac_step!==finishdone (
	echo Resuming from step:!tac_step!
	pause
	goto !tac_step!
)

:startreallyfinish
	set tac_step=startreallyfinish
	set tac_>%tac_workingdir%\CT-Flags.txt
"%tac_workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Really Finish"

%tac_debugmode%

:echostrings
	echo --------------------------------------
	echo Client Info:
	echo Last Name: %tac_lastname%
	echo First name: %tac_firstname%
	echo Date: %tac_FormattedDate%
	echo AV needed?: %no%
	echo Offline?: 
	echo --------------------------------------
	echo,
	
	%tac_debugmode%

:setwindow
	"%tac_workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Really Finish"
	"%tac_workingdir%\nircmd\nircmd.exe" win settopmost title "CleanTech - Really Finish" 1

:boottimer
	set tac_step=boottimer
	set tac_>%tac_workingdir%\CT-Flags.txt

	title CleanTech - BootTimer
	echo Press any key when BootTimer has reported its number.
	echo DO NOT close the BootTimer dialog box yet!
	:: timeout 15
	:: echo Taking back the foreground...
	:: ADD test for BootTimer.exe or w/e
	:: tasklist /FI "IMAGENAME eq BootTimer.exe" 2>NUL | find /I /N "myapp.exe">NUL
	:: if "%ERRORLEVEL%"=="0" echo Program is running
	:: MIGHT actually need sysexp to test this (if ERRORLEVEL==0 when testing for WindowName then kill process)
	::	@For /f "Delims=:" %A in ('tasklist /v /fi "WINDOWTITLE eq WINDOWS BOOT TIME UTILITY"') do @if %A==INFO echo Prog not running

	timeout 30

	:: Certain installations of win7 don't play nice with above list tasklist method for waiting on BootTimer diag. Here's a hacky workaround...

	:waitfortext
	echo testing...
	tasklist /v /fi "IMAGENAME eq BootTimer.exe" > boottimertest2.txt

	findstr /c:"WINDOWS BOOT TIME UTILITY" boottimertest2.txt

	if %errorlevel% NEQ 0 (
		echo not ready...
		timeout 5
		goto waitfortext
	)

	::if !ERRORLEVEL! NEQ 0 (
	::	echo Error level is: %errorlevel%
	::	timeout 2
	::	goto waitfortext
	::)

	:grabnumber
	%tac_debugmode%
	echo Grabbing number from dialog box...
	echo Command running: %tac_workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%tac_clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Postclean.txt"
	"%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%tac_clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Postclean.txt"
	echo,
	%tac_debugmode%
	taskkill /im BootTimer.exe /t
	reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
	%tac_debugmode%
	echo Killing BootTimer.exe's command window
	taskkill /FI "WINDOWTITLE eq %tac_workingdir%\BootTimer.exe"
	timeout 30
	echo Killing BootTimer.exe's browser process
	taskkill /im chrome.exe /f
	taskkill /im iexplore.exe /f
	%tac_debugmode%
	cls & color 1f

title CleanTech - Really Finish

:drivelettertest
	set tac_step=drivelettertest
	set tac_>%tac_workingdir%\CT-Flags.txt

	for %%d in (t u v w x y z) do (if not exist %%d: echo Beast "Clean Up Logs" folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto netmap)

:netmap
	if %tac_offline%==y goto parsing
	echo Mapping Beast "Clean Up Logs" folder to drive letter %netletter%
	echo,

	color E0
	echo Command running: net use %netletter% "\\TechTutors-1\CleanUpLogs" /user:techtutors *
	net use %netletter% "\\TechTutors-1\CleanUpLogs" /p:no /user:techtutors * 
		if errorlevel 1 (
			cls
			color 4f
			echo That didn't seem to work. Pres any key to try again...
			pause
			color E0
			goto netmap
			)
		echo,

		color 1f
	echo Network drive mapped to %netletter%

:parsing
	set tac_step=parsing
	set tac_>%tac_workingdir%\CT-Flags.txt
	echo Let's put together some of the data we've collected...
	:: checkout

:files
	set tac_step=files
	set tac_>%tac_workingdir%\CT-Flags.txt
	title CleanTech: Moving Log Files
	echo Moving Log files
	echo,

	echo Command running: mkdir "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	mkdir "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	echo,

	if /i %tac_offline%==y goto offlinecopy
	echo Copying "%tac_clientdir%" to The BEAST...
	echo robocopy /s "%tac_clientdir%" "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	robocopy /s "%tac_clientdir%" "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	echo ...Done!
	echo,
	goto deletefiles

	:offlinecopy
	echo Copying "%tac_clientdir%" to the Desktop
	echo robocopy /s "%tac_clientdir%" "%HOMEPATH\Desktop\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	robocopy /s "%tac_clientdir%" "%HOMEPATH\Desktop\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
	echo ...Done!
	echo,

	:deletefiles
	set tac_step=deletefiles
	set tac_>%tac_workingdir%\CT-Flags.txt

	title CleanTech: Removing Cleanup Files
	echo Removing cleanup files...
	echo,

	%tac_debugmode%

	echo Command running: logman delete -n CTPostclean
	logman delete -n CTPostclean
	echo,

	echo Command running: logman delete -n CTPreclean
	logman delete -n CTPreclean
	echo,
	
	echo Command running: rd /s /q C:\Logs
	rd /s /q C:\Logs
	echo,
	
	echo Command running: rd /s /q C:\ADW
	rd /s /q C:\ADW
	echo,

	%tac_debugmode%

:restorepoint
	set tac_step=restorepoint
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo Command running: powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
	powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
	%tac_debugmode%
	
:reset
	echo Turning UAC back on...
    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    echo,
    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f


	::Old commands. Should re-import reg from earlier instead, only use this if that fails for some inexplicible reason (AV?)
	::REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
   	::REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /

:userfinish
	set tac_step=userfinish
	set tac_>%tac_workingdir%\CT-Flags.txt

    cls
	color 4f
	echo IMPORTANT	
	echo -------------------------------------------------------------------------
	echo Please double-check that previously disabled AV is re-enabled.
	echo,

	echo Press any key to start SecuritySoftview for a list of AV and firewalls.
	echo,

	echo Once you're done re-activating any AV, close SecuritySoftView to
	echo continue the script.
	echo -------------------------------------------------------------------------
	pause
	echo "Command running: call %tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	call "%tac_workingdir%\securitysoftview\SecuritySoftView.exe"
	
	cls
	color 2f
	echo ---------
	echo All done!
	echo ---------
	echo,
	echo Please take a moment to tidy up the Client's desktop. Thanks!
	echo When you're ready, press enter to remove temporary directories...
	pause
	echo,

	cd %homepath%

	echo,
	echo Command running: rmdir /s /q %tac_perfmondir%
	del /s /q %tac_perfmondir%
	rd /s /q %tac_perfmondir%
	%tac_debugmode%

:hibernateon
powercfg /hibernate on

:finalize
cls
color E0
echo ---------------------------------------------------------------
echo press any key to remove temp folder + startup entry and finish!
pause

:reallyfinishdone
	set tac_step=reallyfinishdone
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-launcher.bat"
	del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-launcher.bat"

	echo Command running: rmdir %tac_workingdir%
	rd /s /q %tac_workingdir%
