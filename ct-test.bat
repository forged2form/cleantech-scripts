:: --------------------
:: CT-Test.BAT
:: --------------------

:: Run through simple tests for client pc's utilizing native windows metrics where possible and falling back to third-party tools and commandlets when windows tools fail.

:: Tests to perform
:: 1. Boot up test (boottimer - I would like to find an alternative to this or create one)
:: 2. Check error logs (wevtutil epl)
:: 3. Dump sysinfo (msinfo32 export - We really should be doing this for all)
:: 4. Check S.M.A.R.T. Status of disks (https://sourceforge.net/projects/smartmontools/files/smartmontools/ - w32 and macOS binaries available)

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
	title CleanTech - PC Test
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo CleanTech - Wrap Up
	echo %horiz_line%
	echo,