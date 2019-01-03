:: Transfer user data
echo off
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
	title CleanTech - User Folder Copier

echo Run this from the Users folder on the System Drive

:foldername
			set input=
			set folder=
			set dest=
			set /p folder="Type directory name: "
			echo,

		:folderconfirm
			set /p input="You entered: %folder%. Is this correct? (y/n): "
			rem %=%
			if /i %input%==y goto foldergood
			if /i %input%==n goto foldername
			echo Incorrect input. & goto folderconfirm

foldergood

set dest=%homepath%\Desktop\%folder%\
mkdir %dest%

takeown /r /a /f %folder%

icacls /t %folder%

xcopy %folder% /f /s /e %dest%

for %i in (Documents,Music,Contacts,Pictures,Video,Favorites,Links,OneDrive,Podcasts,"Saved Games") do xcopy %folder%/%i /f /s /e %dest%/%i