@echo off
:: ------------------------
:: AUTOCLEAN-STARTCLEAN.BAT
:: ------------------------

:: !!!!!!!
:: NOTE: Change location of trontemp. Root of system drive causes issues with some AV even when disabled...
:: !!!!!!!

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

	echo Command running: set "workingdir=C:\CleanTechTemp"
	set "workingdir=C:\CleanTechTemp"
	echo Command running: cd "C:\CleanTechTemp"
	cd "C:\CleanTechTemp"
	echo,

	:echostrings
		echo -----------------------
		echo Client Info:
		echo Last Name: %lastname%
		echo First name: %firstname%
		echo Date: %FormattedDate%
		echo AV needed?: %no%
		echo Debug?: %5
		echo Offline?: 
		echo -----------------------
		echo,

		set lastname=%lastname%
		set firstname=%firstname%
		set FormattedDate=%FormattedDate%
		set debugmode=
		set offline=

		set "clientdir=C:\CleanTechTemp\%lastname%-%firstname%-%FormattedDate%"

	:: set debugmode=rem
	if /i [%5]==[yes] (set debugmode=pause) else (set "debugmode=rem" & goto:setwindow)

	:setwindow
		"C:\CleanTechTemp\nircmd\nircmd.exe" win max ititle "CleanTech - Start Clean"
		"C:\CleanTechTemp\nircmd\nircmd.exe" win settopmost title "CleanTech - Start Clean" 1

	:: --- START boottimer_1-2_pre.bat
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
		%debugmode%
		echo Grabbing number from dialog box...
		echo Command running: "C:\CleanTechTemp\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%lastname%-%firstname%-%FormattedDate%-BootTimer-Preclean.txt"
		"C:\CleanTechTemp\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%lastname%-%firstname%-%FormattedDate%-BootTimer-Preclean.txt"
		echo,
		%debugmode%
		taskkill /im BootTimer.exe /t
		reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
		%debugmode%
		echo Killing BootTimer.exe's command window
		taskkill /FI "WINDOWTITLE eq C:\CleanTechTemp\BootTimer.exe"
		timeout 30
		echo Killing BootTimer.exe's chrome process
		taskkill /im chrome.exe /f
		:: --- END boottimer_1-2_pre.bat
		%debugmode%
		cls & color 1f

	title CleanTech - Start Clean

	%debugmode%
	color E0

	if EXIST autoclean-mbam goto uninstallview
	if EXIST autoclean-startclean goto mbam
	
	:noflagfile
	color 1f
	echo "at :noflagfile"
	echo copy /y NUL autoclean-startclean >NUL
	echo,
	copy /y NUL autoclean-startclean >NUL
	%debugmode%

	::Set up for TechTutors account during safeboot environment
	:ttadminlogin
		echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	    %debugmode%
	    echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\PreStartClean-Winlogon.reg"
	    REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\PreStartClean-Winlogon.reg"

	    goto remflag REM skip for now b/c issues

	    :setautologin
		    echo Setting autologin for Tron session...
		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d TechTutors /f
		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "" /f
		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
		    echo,

	:remflag
	:: Removing autoclean-start flag file
	echo del "C:\CleanTechTemp\autoclean-startclean"
	echo,
	del "C:\CleanTechTemp\autoclean-startclean"

	:: Swapping startup batch files
	echo del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"
	del "%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"

	echo Adding flags to text file
		echo "Start Flags = %lastname% %firstname% %FormattedDate% %no% %5 " >> C:\CleanTechTemp\CT-flags.txt
		echo,

	echo Comand running: echo "C:\CleanTechTemp\autoclean-tron.bat" %lastname% %firstname% %FormattedDate% %no% %5 >C:\CleanTechTemp\autoclean-trontemp.bat
	echo "C:\CleanTechTemp\autoclean-tron.bat" %lastname% %firstname% %FormattedDate% %no% %5 >C:\CleanTechTemp\autoclean-trontemp.bat
	echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,C:\CleanTechTemp\autoclean-trontemp.bat" /f
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,C:\CleanTechTemp\autoclean-trontemp.bat" /f
	%debugmode%

	bcdedit /set {default} safeboot network

	color E0
	echo --------------------
	echo Preparing to reboot.
	echo -------------------- 
	echo,
	echo If tron does not start after reboot,
	echo please launch Tron using autoclean-tron.bat
	echo from the CleanTechTemp directory on the Desktop
	echo,
	%debugmode%

	:shutdown
	shutdown /t 0

	:reboot
	shutdown /r /t 0