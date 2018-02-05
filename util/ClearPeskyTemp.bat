@ECHO off
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
	title TechTutors Utility - Clear Pesky Temp Files
	
	cls
	
		set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutors Utility - Clear Pesky Temp Files
	echo %horiz_line%
	echo,
	
	:clearquestion
	echo,
	set clearq=
	set /p clearq="Would you like to clear temporary system files? (y/n)"
	if %clearq%==y goto cleartempfiles
	if %clearq%==n goto whateverman
	echo,
	echo Invalid input, please press 'y' for yes or 'n' for no. && goto clearquestion
	
	:cleartempfiles
	cd %windir%\temp
	del /f /s /q %windir%\temp\*
	echo,
	if '%errorlevel%' NEQ '0' (color 6f && echo "Something went wrong here... Call TechTutors!") else (color 2f && echo All Clear. Have a good day^^!)
	echo,
	
	pause
	goto EOF
	echo,
	:whateverman
	color E0
	echo,
	echo No? Okay, whatever, man... ^`^`^\^_(^^.^^)^_^/^`^`
	echo,
	pause
	
	EOF