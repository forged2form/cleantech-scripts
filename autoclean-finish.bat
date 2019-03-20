:: --------------------
:: AUTOCLEAN-FINISH.BAT
:: --------------------

:: ADD look for startup folder file "autoclean-trontemp.bat"
:: if it exists, then grab vars from it and continue to finish cleanly
:: or ask for option to restart Tron..
::    - Will need to look into custom restart of Tron with saved Tron stage

@echo off
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
title CleanTech - Wrap Up

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

::finish done test
if !tac_step!==finishdone (
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

if NOT !tac_step!==trondone (
	echo Resuming from step:!tac_step!
	pause
	goto !tac_step!
)

:finishstart
	set tac_step=finishstart
	set tac_>%tac_workingdir%\CT-Flags.txt

"%workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Wrap Up"

%tac_debugmode%

:: WTH ????
::choco install teamviewer vlc chrome -y
::if %no%==y call TrendMicroInstaller.exe

:echostrings
	set tac_step=echostrings
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo --------------------------------------
	echo Client Info:
	echo Last Name: %tac_lastname%
	echo First name: %tac_firstname%
	echo Date: %tac_FormattedDate%
	echo AV needed?: %tac_av%
	echo --------------------------------------
	echo,
	
	%tac_debugmode%

:uninstallview
	set tac_step=uninstallview
	set tac_>%tac_workingdir%\CT-Flags.txt

	call "%workingdir%\pc-decrapifier.exe"

	call "%workingdir%\geek.exe"

echo,
color 1f

:systeminfo
	set tac_step=systeminfo
	set tac_>%tac_workingdir%\CT-Flags.txt
	
	color 1f
	title CleanTech: Performance Test #2

	echo Dumping postclean system info...
	echo Command running: msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-postclean-systeminfo-%tac_FormattedDate%.nfo"
	msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-postclean-systeminfo-%tac_FormattedDate%.nfo"
	echo,

	echo Starting Performance Monitor. Please wait... 
	echo,
	
	echo Importing perfmon xml...
	echo logman import -n CleanTech-PostCleanTest -xml Perfmon-Post.xml
	echo,
	logman import -n CleanTech-PostCleanTest -xml Perfmon-Post.xml

    echo Starting Performance Monitor. Please wait...
	echo,
	
	echo Command running: logman start CleanTech-PostCleanTest
	logman start CleanTech-PostCleanTest

	echo Waiting for perfmon to finish...
    echo timeout 660
	timeout 660
	echo ...Done!
	echo,

:files
	set tac_step=files
	set tac_>%tac_workingdir%\CT-Flags.txt

	title CleanTech: Consolidating Log Files

    echo Copying Performance Monitor logs...
	
	echo Command running: takeown /f c:\perfmon /r /d y
	takeown /f C:\CT-Perfmon\ /r /d y
	
	echo robocopy /s C:\CT-Perfmon\ "%tac_clientdir%\perfmon"
	robocopy /s C:\CT-Perfmon\ "%tac_clientdir%\perfmon"
	echo ...Done!
	echo,
	echo Moving Log files
	echo,

	echo Command running: takeown /f c:\Logs /r /d y
	takeown /f C:\Logs\ /r /d y
	echo Command running: robocopy /s C:\Logs\ "%tac_clientdir%\Logs"
	%tac_debugmode%
	robocopy /s C:\Logs\ "%tac_clientdir%\Logs"
	echo,

	echo Command running: takeown /f c:\ADW /r /d y
	takeown /f C:\ADW\ /r /d y
	echo Command running: robocopy /s C:\ADW "%tac_clientdir%\ADW"
	robocopy /s C:\ADW\ "%tac_clientdir%\ADW"

	title CleanTech: Removing Cleanup Files
	echo Removing cleanup files...
	echo,
	%tac_debugmode%

	echo Command running: logman delete -n CleanTech-PostCleanTest
	logman delete -n CleanTech-PostCleanTest
	echo,

	echo Command running: logman delete -n CleanTech-PreCleanTest
	logman delete -n CleanTech-PreCleanTest
	echo,
	
	%tac_debugmode%

:userfinish
	set tac_step=userfinish
	set tac_>%tac_workingdir%\CT-Flags.txt

    color E0
    echo -------------------------------------------------------
    echo Default browser starting... Please install AdBlock Plus
    echo -------------------------------------------------------
    start /wait http://adblockplus.org

    echo ------------------------------------------------------
    echo WhatInStartup starting... Please check startup entries
    echo ------------------------------------------------------
    start /wait %workingdir%\whatinstartup\WhatInStartup.exe

    echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	%tac_debugmode%

:finishdone
	set tac_stage=reallyfinish
	set tac_step=finishdone
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo Starting BootTimer. Prepare for reboot...
	echo Command running: %workingdir%\boottimer.exe
	echo,
	start %workingdir%\boottimer.exe
	timeout 20
	%workingdir%\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes
