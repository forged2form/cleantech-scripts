@echo off

:: ------------------
:: migratedatatt.bat
:: ------------------

:: Backup ordinary things like browser settings, product keys, installed programs, passwords, and email settings

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
	title TechTutors Data Migration
	
	cls
	r
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutors Util - Windows Data Migration
	echo %horiz_line%
	echo,

	:ingitializeVars
		set netletter=
		set lastname=
		set firstname=
		set filenameformat=

	:formatdate	
	for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
    IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )

    :clientinfo
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

	set filenameformat=%lastname%-%firstname%-%FormattedDate%

	:: --- START map_beast.bat
	:drivelettertest
	for %%d in (t u v w x y z) do (if not exist %%d: echo Beast Utilities folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto netmap)
	
	if offline==y goto cleanupfilesprep
	:netmap
		echo Mapping Beast ClientBackup folder to drive letter %netletter%
		echo,

    	echo Command running: net use %netletter% \\TechTutors-1\Utilities /user:techtutors *
		net use %netletter% \\TechTutors-1\ClientBackup /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%
    :: --- END map_beast.bat

:: Find all user profiles and assign vars to them

:: for /f %users IN (''net users)

::COMMAND copy utilities to local directory
::COMMAND run securitysoftview - DISABLE ALL AV!
::COMMAND run following nirsoft utillities
	:: ie passview - Use "external "
	iepv.exe /stext %filenameformat%-iepv.csv
	passwordfox
	chromepass
	netpass 
	mailpv
	pstpass
	webbrowserpassview.exe /stext %clientfolder%\webbrowserpassview.csv
	windowsvaultpassview
	wirelesskeyview /stext

	uninstallview /stext
	produkey /stext

echo Press any key to log out of the current user and into the TechTutors local admin account
pause

shutdown -L
