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
	echo cd "C:\CleanTechTemp"
	cd "C:\CleanTechTemp"

	set lastname=%lastname%
	set firstname=%firstname%
	set FormattedDate=%FormattedDate%
	set offline=

	set "clientdir=C:\CleanTechTemp\%lastname%-%firstname%-%FormattedDate%"

	"C:\CleanTechTemp/nircmd/nircmd.exe" win max ititle "CleanTech - Wrap Up"
	
	echo copy /y NUL autoclean-finish >NUL
	echo,
	copy /y NUL autoclean-finish >NUL

	echo Setting client info variables
	set lastname=%lastname%
	set firstname=%firstname%
	set FormattedDate=%FormattedDate%
	set av=%no%
	set debugmode=rem
	set offline=
	
	:stringtest
	echo Testing strings...
	echo Last Name: %lastname%
	echo First name: %firstname%
	echo Date: %FormattedDate%
	echo Pause? %debugmode%
	echo Offline? %offline%
	echo,

	%debugmode%
	
	choco install teamviewer vlc chrome -y
	if %no%==y call TrendMicroInstaller.exe

	:echostrings
		echo --------------------------------------
		echo Client Info:
		echo Last Name: %lastname%
		echo First name: %firstname%
		echo Date: %FormattedDate%
		echo AV needed?: %no%
		echo Ninite Installer: %ninite%
		echo --------------------------------------
		echo,
		
		%debugmode%

	:uninstallview

	call "C:\CleanTechTemp\pc-decrapifier.exe"
	
	call "C:\CleanTechTemp\geek.exe"
	echo,
	color 1f

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
	    echo timeout 660
		timeout 660
		echo ...Done!
		echo,

	    echo Copying Performance Monitor logs...
		
		echo Command running: takeown /f c:\perfmon /r /d y
		takeown /f C:\CT-Perfmon\ /r /d y
		
		echo robocopy /s C:\CT-Perfmon\ "%clientdir%\perfmon"
		robocopy /s C:\CT-Perfmon\ "%clientdir%\perfmon"
		echo ...Done!
		echo,
	
	:files
		title CleanTech: Consolidating Log Files
		echo Moving Log files
		echo,

		echo Command running: takeown /f c:\Logs /r /d y
		takeown /f C:\Logs\ /r /d y
		echo Command running: robocopy /s C:\Logs\ "%clientdir%\Logs"
		%debugmode%
		robocopy /s C:\Logs\ "%clientdir%\Logs"
		echo,

		echo Command running: takeown /f c:\ADW /r /d y
		takeown /f C:\ADW\ /r /d y
		echo Command running: robocopy /s C:\ADW "%clientdir%\ADW"
		robocopy /s C:\ADW\ "%clientdir%\ADW"

		title CleanTech: Removing Cleanup Files
		echo Removing cleanup files...
		echo,
		%debugmode%

		echo Command running: logman delete -n CleanTech-PostCleanTest
		logman delete -n CleanTech-PostCleanTest
		echo,

		echo Command running: logman delete -n CleanTech-PreCleanTest
		logman delete -n CleanTech-PreCleanTest
		echo,

		echo Command running: del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		%debugmode%

	:userfinish
	    color E0
	    echo -------------------------------------------------------
	    echo Default browser starting... Please install AdBlock Plus
	    echo -------------------------------------------------------
	    start /wait http://adblockplus.org

	    echo ------------------------------------------------------
	    echo WhatInStartup starting... Please check startup entries
	    echo ------------------------------------------------------
	    start /wait C:\CleanTechTemp\whatinstartup\WhatInStartup.exe

	    echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
		reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
		%debugmode%

		echo Command running: del "C:\CleanTechTemp\autoclean-finish"
		del "C:\CleanTechTemp\autoclean-finish"

		echo Adding flags to text file
		echo "Finish Flags = %lastname% %firstname% %FormattedDate% %no% %5 " >> C:\CleanTechTemp\CT-flags.txt
		echo,

		echo Setting next stage batch file
		echo C:\CleanTechTemp\autoclean-reallyfinish.bat %lastname% %firstname% %FormattedDate% %no% %5 >"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
		%debugmode%

		echo Starting BootTimer. Prepare for reboot...
		echo Command running: C:\CleanTechTemp\boottimer.exe
		echo,
		start C:\CleanTechTemp\boottimer.exe
		timeout 20
		C:\CleanTechTemp\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes
