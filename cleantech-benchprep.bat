@echo off

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
	title TechTutors - Install Chocolatey and Utils

:clientinfo
    :: --- START client_info_entry.bat
        color E0
        echo ------------------------
        echo Please enter client info
        echo ------------------------
        echo,

        :clientname
            set clientnametest=y
            set firstname=
            set lastname=
            set /p firstname="Client's first name: "
            set /p lastname="Client's Last name: "
            echo,

        :clientnameconfirm
            set /p clientnametest="You entered: %firstname% %lastname%. Is this correct? (y/n): "
            rem %=%
            if /i %clientnametest%==y goto clientnamegood
            if /i %clientnametest%==n goto clientname
            echo Incorrect input. & goto clientnameconfirm

        :clientnamegood

    :ttadmin
    ::test for existence of tt admin user
    net user|findstr /i "techtutors"
    if %errorlevel% EQU 0 echo "Techtutors admin already exists. Skipping..." & goto ttpassgood

    :ttadminadd
    net user /add TechTutors
    net localgroup /add administrators TechTutors

    :ttpass
    echo,
    set ttpass=
    set /p ttpass="Please enter TechTutors username password: "

    :ttpassconfirm
    set ttpconfirm=y
    set /p ttpconfirm="You entered %ttpass% , is that correct? (Y/n) "
    if /i %ttpconfirm%==y goto setttpass
    if /i%ttpconfirm%==n goto ttpass
    echo Incorrect input. Try again. & goto ttpassconfirm

    :setttpass
    echo,
    echo Setting TechTutors local admin password...
    net user TechTutors %ttpass%
    echo,

    :ttpassgood
    echo TechTutors admin account ready.
    echo,

    :installutils
    echo Installing Chocolatey...
    echo,
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    echo,
    echo Installing TeamViewer Host...
    echo,
    start /wait teamviewer_host_setup.exe
    echo,
    echo Installing common utilities and apps...
    start /wait choco install -y googlechrome adobereader flashplayerplugin silverlight vlc teamviewer
    echo,
    echo ALL DONE!
    pause

    :DeSuck
    echo "De-Sucking Windows 10... (Well, as much as one CAN De-Suck it at least...)"
    echo,
    ::FIXME! Add ps script and logic for choosing w/ or w/o OD

    :end