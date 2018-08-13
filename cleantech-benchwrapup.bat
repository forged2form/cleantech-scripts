::CleanTech - BenchDone

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
	title TechTutors - Clean Up

    :adminuseroff
    net user /active:no techtutors

    :fixtime
    echo "Fixing Windows Time.."
    net stop w32time

w32tm /unregister

w32tm /register

net start w32time

w32tm /resync
    ::net stop "Windows Time"
    ::reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type /t REG_SZ /d NoSync
    ::net start "Windows Time"
    ::reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type /t REG_SZ /d Sync
    ::net stop "Windows Time"
    ::net start "Windows Time"
    echo "Done!"
    echo,

    :del_remoteaccess
    echo, Uninstalling tightvnc
    choco uninstall -y tightvnc
    echo,
    
    echo,
    echo,
    echo Removing remote access (including Safemode)
    reg import del_remoteaccess.reg

    :del_ttwifi
    echo Removing TechTutors Wi-Fi networks
    echo,
    netsh wlan delete profile name=TechTutors
    netsh wlan delete profile name=TechTutors-5G
    netsh wlan delete profile name=TechTutors-Guest

    :end
    color af
    echo All done!
    pause