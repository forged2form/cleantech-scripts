@echo off
:: ------------------------
:: FAHTDIAGWIN.BAT
:: ------------------------

:: 

chcp 65001

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
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vb	s"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

color 4f
mode 100,35
title %COMPUTERNAME%: FAHT Diag - Windows

SETLOCAL EnableDelayedExpansion

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

echo %horiz_line%
echo FAHT - Windows
echo %horiz_line%
echo,

echo Command running: set "tac_workingdir=C:\CleanTechTemp"
set "tac_workingdir=C:\CleanTechTemp"
echo Command running: cd "%tac_workingdir%"
cd "%tac_workingdir%"
echo,

:: Check for Browser Add-Ons

"%faht_workingdir%"\bin\browseraddonsview.exe /stext "%faht_workingdir%"\addons.txt
type "%faht_workingdir%"\addons.txt | findstr /I "^Name *:" > "%faht_workingdir%"\addons-names.txt

:: Check for Startup Items

"%faht_workingdir%"\bin\whatinstartup.exe /stext "%faht_workingdir%"\startup.txt
type "%faht_workingdir%"\startup.txt | findstr /I "^Name *:" > "%faht_workingdir%"\startup-names.txt

:: Check for AV

"%faht_workingdir%"\bin\securitysoftview.exe /stext "%faht_workingdir%"\av.txt
type "%faht_workingdir%"\av.txt | findstr /I "^Name *:" > "%faht_workingdir%"\av-names.txt

