@echo off

:: ---------------------
:: boottimer_1-2_pre.bat
:: ---------------------

:: %1 is location of batch file to run after timer is complete. If not, exit cleanly, opening text file to view

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

	:: --- START boottimer_1-2_pre.bat

	if NOT defined %1 "set finishaction=notepad %testfile%" else "set finishaction=%1"

	if NOT defined %2 "set testfile=boottimertest" else set testfile=%2

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
			goto :waitfortext
		)

		::if !ERRORLEVEL! NEQ 0 (
		::	echo Error level is: %errorlevel%
		::	timeout 2
		::	goto :waitfortext
		::)

		:grabnumber
		%tac_debugmode%
		echo Grabbing number from dialog box...
		echo Command running: "%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%1-%2-%3-BootTimer-Preclean.txt"
		"%tac_workingdir%\sysexp.exe" /title "WINDOWS BOOT TIME UTILITY" /class Static /stext "%clientdir%\%1-%2-%3-BootTimer-Preclean.txt"
		echo,
		%tac_debugmode%
		taskkill /im BootTimer.exe /t
		reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v WinBooter /f
		%tac_debugmode%
		echo Killing BootTimer.exe's command window
		taskkill /FI "WINDOWTITLE eq %tac_workingdir%\BootTimer.exe"
		timeout 3
		echo Killing BootTimer.exe's chrome process
		taskkill /im chrome.exe /f

		echo "Running command: "%finishaction%
		echo pause
		%finishaction%
		:: --- END boottimer_1-2_pre.bat