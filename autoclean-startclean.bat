rem ------------------------
rem AUTOCLEAN-STARTCLEAN.BAT
rem ------------------------

@echo off
chcp 65001
:: BatchGotAdmin 
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
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
    mode 90,35
	title TechTutor's Clean Up Script - Start Clean
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutor's Clean Up Script - Start Clean
	echo %horiz_line%
	echo,

	set workingdir=c:%HOMEPATH%\Desktop\techtemp
	cd %workingdir%

	if EXISTS autoclean-start goto :flagfile
	
	:noflagfile
	rem creating autoclean-start 'flag' file for next scritps to test for to deduce sucessful completion of this script
	echo copy /y NUL autoclean-startclean >NUL
	echo,
	copy /y NUL autoclean-startclean >NUL
	pause

	:flagfile
	set /i /p "troncompelete=Flag file exists. Did we have to restart before Tron was complete? (y/n) "
	if /i troncomplete==y goto :tronincomplete
	if /i troncomplete==n goto :starttron
	goto :flagfile


	rem !!! Will not work if Tron has to reboot !!!
	echo Setting client-info variable
	set lastname=%1
	set firstname=%2
	set FormattedDate=%3
	echo Testing strings...
	echo Last Name: %lastname%
	echo First name: %firstname%
	echo Date: %FormattedDate%
	echo,

	:starttron
	echo Starting Tron...
	START /WAIT %workingdir%\Tron\tron\Tron.exe -e -str -sdb -sdc
	echo,

	echo Ensuring next boot is in normal mode...
	echo bcdedit /deletevalue {default} safeboot
	bcdedit /deletevalue {default} safeboot
	echo,

	rem Removing autoclean-start flag file
	echo del autoclean-start
	echo,
	del autoclean-start

	echo Restarting...
	echo,
	shutdown /r /p

	pause