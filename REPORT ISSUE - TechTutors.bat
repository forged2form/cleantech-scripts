@echo off

:: ------------------
:: AUTOCLEAN-PREP.BAT
:: ------------------

:: Crappy to do list follows...
:: Look into Task Manager vs. StartupTool (Nirsoft) - REQ from Will
:: In flag file, create last command name for restarting
:: 			(ie: if %6 then set lastcommand = %6)
:: SYSTEM BEEP AT TIMES OF INPUT
:: add test for null entries
:: add test for network connectivity (NIC working & BEAST accessible)
:: look into ability to drag and drop text file or csv with client data,
:: (e.g. name, av needed, password)
:: Should log start time of each script (really, of each command)
::     - Observe logwithdate batch file to see how vocatus accomplishes this
:: Need to swtich away from flags and read from a file instead for the client
:: info. Will be easier to restart one of the stages if something goes sideways.
:: Add test / install for .NET Framework 3.5 (Keep in mind Win 7/8/8.1/10)

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
	title TechTutors - Issue Reporter
	
	cls
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)

	    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )

	set isssue=
	
	echo %horiz_line%
	echo TechTutors - Issue Reporter
	echo %horiz_line%
	echo,


	:issue
	echo,
	echo In one sentence, describe the issue you are experiencing. Press ENTER when done.
	set /p issue=""
	if /i %issue%=="" echo "You didn't enter anything..." && goto :issue

	:issueconfirm
	echo,
	set /p issueconfirm="You entered %issue%. Is this correct? (Please press y or n): "
			if /i %input%==y goto issueconfirmed
			if /i %input%==n goto issue
			echo Incorrect input. Please enter either y or n to confirm your issue. & goto issueconfirm