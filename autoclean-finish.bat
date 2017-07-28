:: --------------------
:: AUTOCLEAN-FINISH.BAT
:: --------------------

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

	set workingdir=C:%HOMEPATH%\Desktop\CleanTechTemp
	echo cd %workingdir% 
	cd %workingdir%

	set lastname=%1
	set firstname=%2
	set FormattedDate=%3

	set "clientdir=%workingdir%\%lastname%-%firstname%-%FormattedDate%"

	%workingdir%/nircmd/nircmd.exe win max ititle "CleanTech - Wrap Up"
	
	echo copy /y NUL autoclean-finish >NUL
	echo,
	copy /y NUL autoclean-finish >NUL

	echo Setting client info variables
	set lastname=%1
	set firstname=%2
	set FormattedDate=%3
	set av=%4
	set chillout=rem nothing to see here
	if defined %5 set chillout=%5 else goto:stringtest	
	
	:stringtest
	echo Testing strings...
	echo Last Name: %lastname%
	echo First name: %firstname%
	echo Date: %FormattedDate%
	echo Pause? %chillout%
	echo,

	%chillout%

	if %4==y set "ninite=Ninite Avira Chrome Teamviewer 12 Installer.exe" & goto :echostrings
	if %4==n set "ninite=Ninite Chrome Teamviewer 12 Installer.exe"

	:echostrings
		echo --------------------------------------
		echo Client Info:
		echo Last Name: %1
		echo First name: %2
		echo Date: %3
		echo AV needed?: %4
		echo Ninite Installer: %ninite%
		echo --------------------------------------
		echo,
		
		%chillout%

	:installutils
		title CleanTech: Installing/Updating Utils
		color E0
		echo ---------------------------------------------
		echo Launching Ninite. Please Close when finished.
		echo ---------------------------------------------
		echo Command running: START "" /WAIT "%workingdir%\%ninite%"
		START "" /WAIT "%workingdir%\%ninite%"
		echo,

	:systeminfo
		color 1f
		title CleanTech: Performance Test #2

		echo Dumping postclean system info...
		echo Command running: msinfo32 /nfo "%clientdir%\%lastname%-%firstname%-postclean-systeminfo-%FormattedDate%.nfo"
		msinfo32 /nfo "%clientdir%\%lastname%-%firstname%-postclean-systeminfo-%FormattedDate%.nfo"
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
	    echo timeout 120
		timeout 120
		echo ...Done!
		echo,

	    echo Copying Performance Monitor logs...
		
		echo Command running: takeown /f c:\perfmon /r /d y
		takeown /f C:\CleanTech\ /r /d y
		
		echo robocopy /s C:\CleanTech\ "%clientdir%\perfmon"
		robocopy /s C:\CleanTech\ "%clientdir%\perfmon"
		echo ...Done!
		echo,
	
	:files
		title CleanTech: Consolidating Log Files
		echo Moving Log files
		echo,

		echo Command running: takeown /f c:\Logs /r /d y
		takeown /f C:\Logs\ /r /d y
		echo Command running: robocopy /s C:\Logs\ "%clientdir%\Logs"
		%chillout%
		robocopy /s C:\Logs\ "%clientdir%\Logs"
		echo,

		echo Command running: takeown /f c:\ADW /r /d y
		takeown /f C:\ADW\ /r /d y
		echo Command running: robocopy /s C:\ADW "%clientdir%\ADW"
		robocopy /s C:\ADW\ "%clientdir%\ADW"

		title CleanTech: Removing Cleanup Files
		echo ::oving cleanup files...
		echo,
		%chillout%

		echo Command running: logman delete -n CleanTech-PostCleanTest
		logman delete -n CleanTech-PostCleanTest
		echo,

		echo Command running: logman delete -n CleanTech-PreCleanTest
		logman delete -n CleanTech-PreCleanTest
		echo,

		echo Command running: del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		%chillout%

	:userfinish
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
		%chillout%

		echo Command running: del %workingdir%\autoclean-finish
		del %workingdir%\autoclean-finish

		echo Setting next stage batch file
		echo %workingdir%\autoclean-reallyfinish.bat %1 %2 %3 %4 %5>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
		%chillout%

		echo Starting BootTimer. Prepare for reboot...
		echo Command running: %workingdir%\boottimer.exe
		echo,
		start %workingdir%\boottimer.exe
		timeout 2
		%workingdir%\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes

	shutdown /r /t 0