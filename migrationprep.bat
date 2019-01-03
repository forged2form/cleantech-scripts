@echo off
:: TIM
:: ------------------
:: MIGRATIONPREP.BAT
:: ------------------

:: Check installed progs list. Export to file.
:: Prompt to Disable A/V temporarily. (CAN WE USE A FLAG FROM WINDOWS DEFENDER TO TEST AND NOT STOP EXECUTION UNTIL RESTARTED AT THE END?)
:: Check for saved passwords in browsers
:: Check for saved Networking indfformation
::   - Static IP
::   - WiFi Passwords
::   - Dump to file
:: Check for current User Profile settings in each user
::   - Desktop icons
::   - Desktop BG
::   - Mouse settings
::   - Text size settings
::   - Default browser settings
:: Check for Email app, calendar and contacts information
::   - Check for WinLiveMail
::       - Export Mailboxes
::       - Export Calendar
::       - Export Address Book
::   - Check for Outlook
::       - Export Mailboxes
::       - Export Calendar
::       - Export Address Book
::   - Check for Thunderbird
::       - Export Mailboxes
::       - Export Calendar
::       - Export Address Book


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
    
    SETLOCAL EnableDelayedExpansion
    color 1f
    mode 100,35
	title CleanTech - Prep Stage
	
	cls

	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo CleanTech - Prep Stage
	echo %horiz_line%
	echo,
