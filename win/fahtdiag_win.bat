@echo off
:: TIM
:: ------------------
:: AUTOCLEAN-PREP.BAT
:: ------------------

:: Crappy to do list follows...
:: Look into Task Manager vs. StartupTool (Nirsoft) - REQ from Will
:: SYSTEM BEEP AT TIMES OF INPUT
:: add test for null entries
:: add test for network connectivity (NIC working & BEAST accessible)
:: Should log start time of each script (really, of each command)
::     - Observe logwithdate batch file to see how vocatus accomplishes this
:: Add test / install for .NET Framework 3.5 (Keep in mind Win 7/8/8.1/10)

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

:windowprep
SETLOCAL EnableDelayedExpansion
color 1f
mode 100,35
title %COMPUTERNAME%: FAHT Diag - Windows Stage

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

set faht_workingdir=C:\FAHT-Temp

if not exist %faht_workingdir%\FAHT-Flags.txt (call faht_prep.bat)

if exist %faht_workingdir%\FAHT-Flags.txt (
	for /f "delims=" %%i in (%faht_workingdir%\FAHT-Flags.txt) do set %%i
	)
	if exist faht-%faht_stage%.bat faht-!faht_stage!.bat
	if exist %faht_workingdir%\faht-!faht_stage!.bat %faht_workingdir%\faht-!faht_stage!.bat
)

echo %horiz_line%
echo FAHT Diag - Windows Stage
echo %horiz_line%
echo,

echo Testing operating system...
echo ---------------------------
echo,

:winvertest
	for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
	if "%version%" == "10.0" set tac_winver=Win10
	if "%version%" == "6.3" set tac_winver=Win8.1
	if "%version%" == "6.2" set tac_winver=Win8
	if "%version%" == "6.1" set tac_winver=Win7
	if "%version%" == "6.0" set tac_winver=WinVista

:: CHANGEME

echo Adding autologon scripts to Startup...
echo Command running: copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"
copy "autoclean-launcher.bat" "C:\%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"

echo Testing for OS Updates...
echo ---------------------------
echo,

echo Running Performance Monitor Test....
echo ------------------------------------
echo,

echo Looking for BLOAT...
echo --------------------
echo,

echo Looking for AV...
echo -----------------
echo,

:: securitysoftview

echo Looking for backup...
echo ---------------------
echo,

echo Manual steps...
echo ---------------
echo,

