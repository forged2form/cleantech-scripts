@ echo off
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
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
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

	echo Command running: set workingdir=c:%HOMEPATH%\Desktop\CleanTechTemp
	set workingdir=c:%HOMEPATH%\Desktop\CleanTechTemp
	echo Command running: cd %workingdir%
	cd %workingdir%
	echo,

	:echostrings
		echo -----------------------
		echo Client Info:
		echo Last Name: %1
		echo First name: %2
		echo Date: %3
		echo AV needed?: %4
		echo Debug?: %5
		echo Offline?: %6
		echo -----------------------
		echo,

		set lastname=%1
		set firstname=%2
		set FormattedDate=%3
		set offline=%6

		set "clientdir=%workingdir%\%lastname%-%firstname%-%FormattedDate%"

	:: set debugmode=rem nothing to see here
	if /i [%5]==[yes] (set debugmode=pause) else (set "debugmode=rem nothing to see here" & goto:setwindow)

	:setwindow
		%workingdir%\nircmd\nircmd.exe win max ititle "CleanTech - Start Clean"
		%workingdir%\nircmd\nircmd.exe win settopmost title "CleanTech - Start Clean" 1

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

		:waitfortext
		echo testing...
		tasklist /v /fi "IMAGENAME eq BootTimer.exe" | find "WINDOWS BOOT TIME UTILITY"
		if %ERRORLEVEL% NEQ 0 (
			timeout 2
			echo %errorlevel%
			goto :waitfortext
		) else ( goto :grabnumber )

		:grabnumber
		%debugmode%
		echo Grabbing number from dialog box...
		echo Command running: %workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%1-%2-%3-BootTimer-Preclean.txt"
		%workingdir%\sysexp.exe /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%1-%2-%3-BootTimer-Preclean.txt"
		echo,
		%debugmode%
		taskkill /im BootTimer.exe /t
		reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
		%debugmode%
		echo Killing BootTimer.exe's command window
		taskkill /FI "WINDOWTITLE eq %workingdir%\BootTimer.exe"
		echo Killing BootTimer.exe's chrome process
		taskkill /im chrome.exe /f
		%debugmode%
		cls & color 1f

	title CleanTech - Start Clean

	%debugmode%
	color E0

	if EXIST autoclean-mbam goto :uninstallview
	if EXIST autoclean-startclean goto :mbam
	
	:noflagfile
	color 1f
	echo at :noflagfile
	echo copy /y NUL autoclean-startclean >NUL
	echo,
	copy /y NUL autoclean-startclean >NUL
	%debugmode%
	goto mbam

	:mbam
	color E0
	echo At :mbam
	echo Launching MBAM...

	copy /y NUL autoclean-mbam >NUL
:: JOB: MBAM (Malwarebytes Anti-Malware)
if exist "%ProgramFiles%\Malwarebytes Anti-Malware\mbam.exe" set EXISTING_MBAM=yes
if exist "%ProgramFiles%\Malwarebytes\Anti-Malware\mbam.exe" set EXISTING_MBAM=yes
if exist "%ProgramFiles(x86)%\Malwarebytes Anti-Malware\mbam.exe" set EXISTING_MBAM=yes
if exist "%ProgramFiles(x86)%\Malwarebytes\Anti-Malware\mbam.exe" set EXISTING_MBAM=yes
if /i %EXISTING_MBAM%==yes (
	goto skip_mbam
)
		REM "stage_3_disinfect\mbam\Malwarebytes Anti-Malware v3.0.4.1269.exe" /verysilent
		FOR /f "tokens=*" %%G IN ('dir /b %workingdir%\Tron\tron\resources\stage_3_disinfect\mbam\Malwarebytes*.exe') DO "%%G" /SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /NOCANCEL
		if exist "%PUBLIC%\Desktop\Malwarebytes Anti-Malware.lnk" del "%PUBLIC%\Desktop\Malwarebytes Anti-Malware.lnk"
		if exist "%USERPROFILES%\Desktop\Malwarebytes Anti-Malware.lnk" del "%USERPROFILES%\Desktop\Malwarebytes Anti-Malware.lnk"
		if exist "%ALLUSERSPROFILE%\Desktop\Malwarebytes Anti-Malware.lnk" del "%ALLUSERSPROFILE%\Desktop\Malwarebytes Anti-Malware.lnk"
		copy /y %workingdir%\Tron\tron\resources\stage_3_disinfect\mbam\settings.conf "%ProgramData%\Malwarebytes\Malwarebytes Anti-Malware\Configuration\settings.conf" >> "%LOGPATH%\%LOGFILE%" 2>NUL

		:: Install the bundled definitions file and integrate the log into Tron's log
		stage_3_disinfect\mbam\mbam2-rules.exe /sp- /verysilent /suppressmsgboxes /log="%clientdir%\mbam_rules_install.log" /norestart

		:: Scan for and launch appropriate architecture version
		if exist "%ProgramFiles(x86)%\Malwarebytes Anti-Malware\mbam.exe" start "" "%ProgramFiles(x86)%\Malwarebytes Anti-Malware\mbam.exe"
		if exist "%ProgramFiles%\Malwarebytes Anti-Malware\mbam.exe" start "" "%ProgramFiles%\Malwarebytes Anti-Malware\mbam.exe"
	)
)
:skip_mbam
pause

	:uninstallview
	call %workingdir%/NirSoft/uninstallview.exe
	echo Command running: del autoclean-mbam
	del autoclean-mbam
	echo,
	color 1f

	pause

	:: Removing autoclean-start flag file
	echo del %workingdir%\autoclean-startclean
	echo,
	del %workingdir%\autoclean-startclean

	:: Swapping startup batch files
	echo del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"
	del "C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"

	echo Comand running: echo %workingdir%\autoclean-tron.bat %1 %2 %3 %4 %5 %6>C:\autoclean-trontemp.bat
	echo %workingdir%\autoclean-tron.bat %1 %2 %3 %4 %5 %6>C:\autoclean-trontemp.bat
	echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,c:\autoclean-trontemp.bat" /f
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe,c:\autoclean-trontemp.bat" /f
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

	shutdown /r /t 0