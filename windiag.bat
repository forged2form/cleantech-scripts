@echo off

:: ------------------
:: windiag.bat
:: ------------------

:: Run system and extra utilities to diagnose and collect system info for client computers

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
	title TechTutors - Diagnostics
	
	cls
	r
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutors - Diagnostics
	echo %horiz_line%
	echo,


	:ingitializeVars
		set netletter=
		set lastname=
		set firstname=

	clientinfo
	:: --- START client_info_entry.bat
		color E0
		echo ------------------------
		echo Please enter client info
		echo ------------------------
		echo,

		:clientname
			set firstname=
			set lastname=
			set /p firstname="Client's first name: "
			set /p lastname="Client's Last name: "
			echo,

		:clientnameconfirm
			set /p input="You entered: %firstname% %lastname%. Is this correct? (y/n): "
			rem %=%
			if /i %input%==y goto clientnamegood
			if /i %input%==n goto clientname
			echo Incorrect input. & goto clientnameconfirm

		:clientnamegood
	:: --- END client_info_entry.bat

	:: --- START map_beast.bat
	:drivelettertest
	for %%d in (t u v w x y z) do (if not exist %%d: echo Beast Utilities folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto netmap)
	
	if offline==y goto cleanupfilesprep
	:netmap
		echo Mapping Beast Utilities folder to drive letter %netletter%
		echo,

    	echo Command running: net use %netletter% \\TechTutors-1\Utilities /user:techtutors *
		net use %netletter% \\TechTutors-1\Utilities /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%
    :: --- END map_beast.bat

	powercfg /energy
	ren energy-report.html %lastname%-%firstname%-%FormattedDate%-energy-report.html