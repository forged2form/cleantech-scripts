
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
	echo cd "C:\CleanTechTemp"
	cd "C:\CleanTechTemp"
	set "clientdir=%tac_workingdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"

	"%tac_workingdir%\nircmd\nircmd.exe" win max ititle "CleanTech - Really Finish"
	
	echo copy /y NUL "%tac_workingdir%\autoclean-reallyfinish" >NUL
	echo,
	copy /y NUL "%tac_workingdir%\autoclean-reallyfinish" >NUL

	set tac_debugmode=rem nothing to see here
	
	:stringtest
	echo Testing strings...
	echo Last Name: %tac_lastname%
	echo First name: %tac_firstname%
	echo Date: %tac_FormattedDate%
	echo Pause? %tac_debugmode%
	echo,

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
		echo Command running: %tac_workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Postclean.txt"
		"%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%-BootTimer-Postclean.txt"
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
		%tac_debugmode%
		cls & color 1f

	title CleanTech - Really Finish

	:drivelettertest
		for %%d in (t u v w x y z) do (if not exist %%d: echo Beast "Clean Up Logs" folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto netmap)

	:netmap
		if %tac_offline%==y goto parsing
		echo Mapping Beast "Clean Up Logs" folder to drive letter %netletter%
		echo,

		color E0
    	echo Command running: net use %netletter% "\\TechTutors-1\CleanUpLogs" /user:techtutors *
		net use %netletter% "\\TechTutors-1\CleanUpLogs" /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%

	:parsing
		echo Let's put together some of the data we've collected...
		:: checkout
	
	:files
		title CleanTech: Moving Log Files
		echo Moving Log files
		echo,

		echo Command running: mkdir "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		mkdir "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		echo,

		if /i %tac_offline%==y goto offlinecopy
		echo Copying "%clientdir%" to The BEAST...
		echo robocopy /s "%clientdir%" "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		robocopy /s "%clientdir%" "%netletter%\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		echo ...Done!
		echo,
		goto deletefiles

		:offlinecopy
		echo Copying "%clientdir%" to the Desktop
		echo robocopy /s "%clientdir%" "%HOMEPATH\Desktop\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		robocopy /s "%clientdir%" "%HOMEPATH\Desktop\%tac_lastname%-%tac_firstname%-%tac_FormattedDate%"
		echo ...Done!
		echo,

		:deletefiles
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
		
		echo Command running: rd /s /q C:\Logs
		rd /s /q C:\Logs
		echo,
		
		echo Command running: rd /s /q C:\ADW
		rd /s /q C:\ADW
		echo,

		echo Command running: del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
		echo,
		%tac_debugmode%

	:restorepoint
		echo Command running: powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
		powershell "Checkpoint-Computer -Description 'CleanTech: Post-Clean checkpoint'"
		%tac_debugmode%
		
	:reset
		echo Turning UAC back on...
	    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
	    echo,
	    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f

	    echo Removing AutoLogon
		::Old commands. Should re-import reg from earlier instead, only use this if that fails for some inexplicible reason (AV?)
		::REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
	   	::REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /
	   	REG IMPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\Preclean-Winlogon.reg" /f

	:userfinish
	    color E0

	    echo -------------------------------------------------------------
	    echo WhatInStartup starting... Please double-check startup entries
	    echo -------------------------------------------------------------
	    start /wait C:\CleanTechTemp/whatinstartup/WhatInStartup.exe
		
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
		echo Command running: rmdir C:\CleanTechTemp
		if exist "C:\autoclean-prep.bat" del c:\C:\autoclean-prep.bat /q
	rem	rmdir "C:\CleanTechTemp" /s /q
		%tac_debugmode%

		echo Adding flags to text file
		echo "Really Finish Flags = %tac_lastname% %tac_firstname% %tac_FormattedDate% %no% %5 " >> %tac_workingdir%\CT-flags.txt
		echo,

:done

:hibernateon
powercfg /hibernate on

:finalize
echo press any key to remove startup entry and finish!
pause
echo del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-reallyfinishtemp.bat"
