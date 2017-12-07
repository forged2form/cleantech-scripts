:: ------------------
:: Autoclean-Tron.bat
:: ------------------

:: @echo off
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
	title CleanTech - Tron
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo CleanTech - Tron Stage
	echo %horiz_line%
	echo,
	
	set "workingdir=C:\CleanTechTemp"
	echo cd "C:\CleanTechTemp"
	cd "C:\CleanTechTemp"

	debugmode=rem nothing to see here
	if defined %5 set debugmode=%5

	:echostrings
		color E0
		echo -----------------------
		echo Client Info:
		echo Last Name: %1
		echo First name: %2
		echo Date: %3
		echo AV needed?: %4
		echo Offline?: %6
		echo -----------------------
		echo,

		set lastname=%1
		set firstname=%2
		set FormattedDate=%3
		set offline=%6

		set "clientdir=C:\CleanTechTemp\%lastname%-%firstname%-%FormattedDate%"


	echo Adding flags to text file
		echo "Tron Flags = %1 %2 %3 %4 %5 %6" >> C:\CT-flags.text
		echo,

	color 1f

	:nir
		C:\CleanTechTemp\nircmd\nircmd.exe win min process explorer.exe

			:reboot-prep
		echo Ensuring next boot is in normal mode...
		echo bcdedit /deletevalue {default} safeboot
		bcdedit /deletevalue {default} safeboot
		echo,

		:putshellback
		echo Removing trontemp batch file...
		del C:\autoclean-trontemp.bat

	echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	%debugmode%

		:: echo "Command running: REG IMPORT /f "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\PreStartClean-Winlogon.reg""
		:: REG IMPORT /f "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\PreStartClean-Winlogon.reg" /f
		pause

		echo Setting next stage batch file
		echo C:\CleanTechTemp\autoclean-finish.bat %1 %2 %3 %4 %5 %6>"%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
		%debugmode%

	:starttron
		echo Starting Tron...
		C:\CleanTechTemp\Tron\tron\Tron.bat -a -str -sdb -sdc
		echo,

	:: THIS IS NOT WORKING AS INTENDED RIGHT NOW -- if NOT exist "C:\CleanTechTemp\Tron\tron\resources\tron_stage.txt" (


		shutdown /r /t 0
	::	) else shutdown /r /t 0