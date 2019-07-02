@echo off

:: -----------------------
:: create_ttlocaladmin.bat
:: -----------------------

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

net user /add techtutors
net localgroup /add administrators techtutors

:ttpassword
	set ttpass=
	set/p ttpassword="Enter password for TechTutors local acccount: "
	if /i %ttpassword%=="" echo You didn't enter anything! *Sigh* Try again... & goto passwordneeded

	:passconfirm
	echo You entered: %ttpassword%
	set passconfirm=
	set /p passconfirm="Is this correct? (y/n): "

	if /i %passconfirm%==y goto passcorrect
	if /i %passconfirm%==n goto passwordneeded
	echo Incorrect input. & goto passconfirm
	:passcorrect

:ttuserpassset
	net user techtutors %ttpasssword%
