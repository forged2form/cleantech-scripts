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
	title TechTutors - PC Customizations

    if not exist "%systemdrive%\ProgramData\chocolatey\bin\choco.exe" goto chocoinstall
    choco upgrade all
    goto installapps

    :chocoinstall
    echo Installing Chocolatey...
    echo,

    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%profilesfolder%\Public\chocolatey\bin"
    echo,

    :installapps
    echo Installing TeamViewer 13
    echo,
    start /wait TeamViewer13_Setup.exe
    echo Installing Bonjour, LibreOffice-Fresh, Chome, VLC, Acrobat Reader, Flash, Silverlight, and JRE
    echo "choco install -y bonjour libreoffice-fresh googlechrome vlc adobereader flashplayerplugin silverlight javaruntime"
    echo,
    start /wait choco install -y bonjour libreoffice-fresh googlechrome vlc adobereader flashplayerplugin silverlight javaruntime

    :: LO settings section credit to AlphaTwin from openoffice forums 

    :loscheck
    if not exist "%appdata%\LibreOffice\4\user\registrymodifications.xcu" goto losettings
    goto DeSuck

    :losettings
    start " " /min "%systemdrive%\Program Files\LibreOffice\program\soffice.exe"
    
    :loop
    timeout /t 15
    if not exist "%appdata%\LibreOffice\4\user" goto :loop
    goto copylosettings

    :copylosettings
    taskkill /f /t /im soffice.bin

    echo "copy /y LOSettings\registrymodifications.xcu "%appdata%\LibreOffice\4\user\registrymodifications.xcu""
    echo,
    copy /y LOSettings\registrymodifications.xcu "%appdata%\LibreOffice\4\user\registrymodifications.xcu"

    :DeSuck
    echo "Running DeSuck"
    echo,
    cd "DeSuck Win10"
    powershell -ExecutionPolicy Bypass .\Win10TechTutors-2.4.ps1

    :remicons
    del /q /s "%systemdrive%\Users\Public\Desktop\Acrobat Reader DC.lnk"
    del /q /s "%systemdrive%\Users\Public\Desktop\VLC Media Player.lnk"
    del /q /s "%systemdrive%\Users\Public\Desktop\Edge.lnk"

    :finished
    echo "Automation done! :)"
    echo,
    echo "----------------------------------------------------------------"
    echo "Now you need to..."
    echo,
    echo "+ Clean up the Start Menu with anything left."
    echo "+ Pin Chrome to Taskbar and Start."
    echo "+ Pin This PC to start."
    echo "+ Enlarge Weather and turn on location for Weather app."
    echo "+ Install ABP in Chrome."
    echo "+ Set Chrome default. Set Adobe Reader default."
    echo "+ Clean up Desktop apps and delete AUTOBENCH folder."
    echo "+ Check for updates and wait while Windows updates and installs."
    echo "----------------------------------------------------------------"
    echo,
    pause