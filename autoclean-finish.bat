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
title %COMPUTERNAME%: CleanTech - Wrap Up

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

"%workingdir%\nircmd\nircmd.exe" win max ititle %COMPUTERNAME%: "CleanTech - Wrap Up"

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

	color 4f
	cls
	echo -------------------------------------------------------------------------
	echo UninstallView
	echo -------------------------------------------------------------------------
	echo MANUAL STEP
	echo -------------------------------------------------------------------------
	echo Two programs will open. PC Decrapifier and Geek Uninstaller.
	echo Please go through PC-D first, and allow it to finish.
	echo,
	echo Note: You might need to click 'skip' on some uninstallations if they hand.
	echo If prompted, do not stop running scripts on the page.
	echo,
	echo Finish with Geek uninstaller to remove anything PC-D couldn't remove or
	echo see. Once you close the Geek Uninstaller window, the autoclean script
	echo will resume.
	echo -------------------------------------------------------------------------
	pause

	set tac_step=uninstallview
	set tac_>%tac_workingdir%\CT-Flags.txt

	"%workingdir%\pc-decrapifier.exe"

	"%workingdir%\geek.exe"

echo,
color 1f

:systeminfo
	set tac_step=systeminfo
	set tac_>%tac_workingdir%\CT-Flags.txt
	
	color 1f
	title %COMPUTERNAME%: CleanTech: Performance Test #2

	echo Dumping postclean system info...
	echo Command running: msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-postclean-systeminfo-%tac_FormattedDate%.nfo"
	msinfo32 /nfo "%tac_clientdir%\%tac_lastname%-%tac_firstname%-postclean-systeminfo-%tac_FormattedDate%.nfo"
	echo,

    echo Starting Performance Monitor. Please wait...
	echo,
	
	echo Command running: logman start CTPostclean
	logman start CTPostclean

	echo Waiting for perfmon to finish...
    echo timeout 660
	timeout 660
	echo ...Done!
	echo,

:files
	set tac_step=files
	set tac_>%tac_workingdir%\CT-Flags.txt

	title %COMPUTERNAME%: CleanTech: Consolidating Log Files

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

	title %COMPUTERNAME%: CleanTech: Removing Cleanup Files
	echo Removing cleanup files...
	echo,
	%tac_debugmode%

	echo Command running: logman delete -n CTPostclean
	logman delete -n CTPostclean
	echo,

	echo Command running: logman delete -n CTPreclean
	logman delete -n CTPreclean
	echo,

	%tac_debugmode%

:userfinish
	set tac_step=userfinish
	set tac_>%tac_workingdir%\CT-Flags.txt

    color E0
    cls
    echo -------------------------------------------------------
    echo Default browser starting... Please install AdBlock Plus
    echo -------------------------------------------------------
	echo MANUAL STEP	
	echo -------------------------------------------------------------------
	echo Adblockplus.org will load in the deault browers. Please install the
	echo extension. Closing the browser will bring the next step.
	echo,
	echo Press a key to continue and close the browser window when you're
	echo finished to move on to the next step.
	echo -------------------------------------------------------------------
	pause

    start /wait http://adblockplus.org

    cls
    echo ------------------------------------------------------
    echo WhatInStartup starting... Please check startup entries
    echo ------------------------------------------------------
   	echo MANUAL STEP	
	echo -------------------------------------------------------------------
	echo Please check for any remaining startup entires using WhatInStartup.
	echo Delete any that you are sure that are unecessary.title
	echo,
	echo Press a key to continue and close the browser window when you're
	echo finished to move on to the next step.
	echo -------------------------------------------------------------------
	pause
    start /wait %workingdir%\whatinstartup\WhatInStartup.exe

    echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	%tac_debugmode%

:finishdone
	set tac_stage=reallyfinish
	set tac_step=finishdone
	set tac_>%tac_workingdir%\CT-Flags.txt

	cls
	echo -----------------------------------------
	echo Starting BootTimer. Prepare for reboot...
	echo -----------------------------------------
	echo You can either let the countdown reboot
	echo for you, or you can choose to reboot via
	echo the dialogue box that opens. Your call.
	echo,

	echo Command running: %workingdir%\boottimer.exe
	echo,
	start %workingdir%\boottimer.exe

	timeout 20
	%workingdir%\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes
