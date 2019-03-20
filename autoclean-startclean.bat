@echo off
:: ------------------------
:: AUTOCLEAN-STARTCLEAN.BAT
:: ------------------------

chcp 65001

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
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vb	s"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

color 4f
mode 100,35
title CleanTech - Start Clean

SETLOCAL EnableDelayedExpansion

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

echo %horiz_line%
echo CleanTech - Start Clean
echo %horiz_line%
echo,

echo Command running: set "tac_workingdir=C:\CleanTechTemp"
set "tac_workingdir=C:\CleanTechTemp"
echo Command running: cd "%tac_workingdir%"
cd "%tac_workingdir%"
echo,

echo Printing Last run variables:
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do echo %%i
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do set %%i

::startcleandone test
if !tac_step!==startcleandone (
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

if NOT !tac_step!==prepdone (
	echo Resuming from step:!tac_step!
	pause
	goto !tac_step!
)

:startclean
	set tac_step=startcleanstart
	set tac_>%tac_workingdir%\CT-Flags.txt

:echostrings
	set tac_step=echostrings
	set tac_>%tac_workingdir%\CT-Flags.txt
	echo -----------------------
	echo Client Info:
	echo Last Name: %tac_lastname%
	echo First name: %tac_firstname%
	echo Date: %tac_FormattedDate%
	echo Offline?: %tac_offline%
	echo -----------------------
	echo,

:: Clientdir should already be present in flag file now...
::	set "tac_clientdir=%tac_workingdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"

:setwindow
	"%tac_workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Start Clean"
	"%tac_workingdir%\nircmd\nircmd.exe" win settopmost title "CleanTech - Start Clean" 1

:: --- START boottimer_1-2_pre.bat
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
	tasklist /v /fi "IMAGENAME eq BootTimer.exe" > boottimertest1.txt

	findstr /c:"WINDOWS BOOT TIME UTILITY" boottimertest1.txt

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
	echo Command running: "%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%tac_clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Preclean.txt"
	"%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%tac_clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Preclean.txt"
	echo,
	%tac_debugmode%
	taskkill /im BootTimer.exe /t
	reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
	%tac_debugmode%
	echo Killing BootTimer.exe's command window
	taskkill /FI "WINDOWTITLE eq %tac_workingdir%\BootTimer.exe"
	timeout 30
	echo Killing BootTimer.exe's chrome process
	taskkill /im chrome.exe /f
	:: --- END boottimer_1-2_pre.bat
	%tac_debugmode%
	cls & color 1f

title CleanTech - Start Clean

%tac_debugmode%
:: !!!! What's going on here again?
::color E0
::
::if EXIST autoclean-mbam goto uninstallview
::if EXIST autoclean-startclean goto mbam

::noflagfile
::color 1f
%tac_debugmode%


:restartprep
	set tac_step=restartprep
	set tac_>%tac_workingdir%\CT-Flags.txt

	
	::Set up for TechTutors account during safeboot environment
	:ttadminlogin
		echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		%tac_debugmode%
		echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\PreStartClean-Winlogon.reg"
		REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\PreStartClean-Winlogon.reg"

	:setautologin
	    echo Setting autologin for Tron session...
	   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d TechTutors /f
	   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "" /f
	   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
	    echo,

	:safemodestart
		echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,%tac_workingdir%\autoclean-launcher.bat" /f
		reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,%tac_workingdir%\autoclean-launcher.bat" /f
		%tac_debugmode%

		bcdedit /set {default} safeboot network


:startcleandone
	set tac_step=startcleandone
	set tac_stage=tron
	set tac_>%tac_workingdir%\CT-Flags.txt

	color E0
	echo --------------------
	echo Preparing to reboot.
	echo -------------------- 
	echo,
	echo If tron does not start after reboot,
	echo please launch Tron using autoclean-tron.bat
	echo from the CleanTechTemp directory on the Desktop
	echo,
	%tac_debugmode%

	:reboot
	shutdown /r /t 0