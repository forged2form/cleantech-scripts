:: --------------------------
:: AUTOCLEAN-REALLYFINISH.BAT
:: --------------------------

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

	set workingdir=C:%HOMEPATH%\Desktop\CleanTechTemp
	echo cd %workingdir% 
	cd %workingdir%

	%workingdir%/nircmd/nircmd.exe win max ititle "CleanTech - Really Finish"
	
	echo copy /y NUL autoclean-reallyfinish >NUL
	echo,
	copy /y NUL autoclean-reallyfinish >NUL

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

	:setwindow
		%workingdir%\nircmd\nircmd.exe win max ititle "CleanTech - Really Finish"
		%workingdir%\nircmd\nircmd.exe win settopmost title "CleanTech - Really Finish" 1

	:boottimer
		title CleanTech - BootTimer 2
		echo Press any key when BootTimer has reported its number.
		echo DO NOT close the BootTimer dialog box yet!
		:: timeout 15
		:: echo Taking back the foreground...
		:: ADD test for BootTimer.exe or w/e
		:: tasklist /FI "IMAGENAME eq BootTimer.exe" 2>NUL | find /I /N "myapp.exe">NUL
		:: if "%ERRORLEVEL%"=="0" echo Program is running
		:: MIGHT actually need sysexp to test this (if ERRORLEVEL==0 when testing for WindowName then kill process)
		::	@For /f "Delims=:" %A in ('tasklist /v /fi "WINDOWTITLE eq WINDOWS BOOT TIME UTILITY"') do @if %A==INFO echo Prog not running
		
	:waitfortext
		echo testing...
		tasklist /v /fi "IMAGENAME eq BootTimer.exe" | find "WINDOWS BOOT TIME UTILITY"
		if !ERRORLEVEL! EQU 1 (
			timeout 2
			echo !errorlevel!
			goto :waitfortext
		) else ( goto :grabnumber )

		:grabnumber
		%chillout%
		echo Grabbing number from dialog box...
		echo Command running: %workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%1-%2-%3-BootTimer-Postclean.txt"
		%workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%workingdir%\%1-%2-%3-BootTimer-Postclean.txt"
		echo,
		%chillout%
		taskkill /im BootTimer.exe /t
		reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
		%chillout%
		echo Killing BootTimer.exe's command window
		taskkill /FI "WINDOWTITLE eq %workingdir%\BootTimer.exe"
		echo Killing BootTimer.exe's chrome process
		taskkill /im chrome.exe /f
		%chillout%
		cls & color 1f

	title CleanTech - Really Finish

	:drivelettertest
		for %%d in (a b c d e f g h i j k l m n o p q r s t u v) do (if not exist %%d: echo Beast documents folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto :netmap)

	:netmap
		echo Mapping Beast Documents folder to drive letter %netletter%
		echo,

		color E0
    	echo Command running: net use %netletter% \\BEAST\Documents /user:techtutors *
		net use %netletter% \\BEAST\Documents /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto :netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%
	
	:files
		title CleanTech: Moving Log Files
		echo Moving Log files
		echo,

		echo Copying %clientdir% to The BEAST...
		echo robocopy /s %clientdir% "%netletter%\Clean Up Logs\"
		robocopy /s %clientdir% "%netletter%\Clean Up Logs\"
		echo ...Done!
		echo,

		title CleanTech: Removing Cleanup Files
		echo Removing cleanup files...
		echo,

		%chillout%

		echo Command running: logman delete -n CleanTech-PostCleanTest
		logman delete -n CleanTech-PostCleanTest
		echo,

		echo Command running: logman delete -n CleanTech-PreCleanTest
		logman delete -n CleanTech-PreCleanTest
		echo,
		
		echo Command running: rd /s /q C:\Logs
		rd /s /q C:\Logs
		echo,
		
		echo Command running: rd /s /q C:\ADW
		rd /s /q C:\ADW
		echo,

		echo Command running: del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
		echo,
		%chillout%

	:restorepoint
		echo Command running: powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
		powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
		%chillout%
		
	:reset
		echo Turning UAC back on...
	    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
	    echo,
	    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f

	    echo Removing AutoLogon
		REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
	   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f

	:userfinish
	    color E0
	    echo -------------------------------------------------------
	    echo Default browser starting... Please install AdBlock Plus
	    echo -------------------------------------------------------
	    start /wait http://adblockplus.org

	    echo ------------------------------------------------------
	    echo WhatInStartup starting... Please check startup entries
	    echo ------------------------------------------------------
	    start /wait %workingdir%/whatinstartup/WhatInStartup.exe
		
		cls
		color 2f
		echo ---------
		echo All done!
		echo ---------
		echo,
		echo Please take a moment to tidy up the Client's desktop. Thanks!
		echo When you're ready, press enter to remove temporary directory...
		pause
		echo,

		cd %homepath%
		echo Command running: rmdir %workingdir%
		rmdir %workingdir% /s /q
		%chillout%
