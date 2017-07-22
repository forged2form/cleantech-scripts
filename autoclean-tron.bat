rem ------------------
rem Autoclean-Tron.bat
rem ------------------

@echo off
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
    mode 100,35
	title TechTutor's Clean Up Script - Prep Stage
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutor's Clean Up Script - Prep Stage
	echo %horiz_line%
	echo,
	
	set workingdir=c:%HOMEPATH%\Desktop\techtemp
	mkdir %workingdir%
	echo cd %workingdir%
	cd %workingdir%

	:echostrings
	echo -----------------------
	echo Client Info:
	echo Last Name: %1
	echo First name: %2
	echo Date: %3
	echo AV needed?: %4
	echo -----------------------
	echo,

	pause

	rem NOTE: Need new batch file for Tron. (autoclean-tron.bat) that will be placed in shell registry entry for autostartup after in Safe mode. Code following this comment should be responsible for accomplishing that.
	:starttron
	echo Starting Tron...
	START /WAIT %workingdir%\Tron\tron\Tron.exe -e -str -sdb -sdc
	echo,

	echo Ensuring next boot is in normal mode...
	echo bcdedit /deletevalue {default} safeboot
	bcdedit /deletevalue {default} safeboot
	echo,

	echo Setting next stage batch file
	echo %workingdir%\autoclean-finish.bat %1 %2 %3 %4>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-finishtemp.bat"
	pause