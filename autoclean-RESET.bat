@echo off
:: TIM
:: -------------------
:: AUTOCLEAN-RESET.BAT
:: -------------------

:: Crappy to do list follows...
:: Look into Task Manager vs. StartupTool (Nirsoft) - REQ from Will
:: In flag file, create last command name for restarting
:: 			(ie: if  then set lastcommand = )
:: SYSTEM BEEP AT TIMES OF INPUT
:: add test for null entries
:: add test for network connectivity (NIC working & BEAST accessible)
:: look into ability to drag and drop text file or csv with client data,
:: (e.g. name, av needed, password)
:: Should log start time of each script (really, of each command)
::     - Observe logwithdate batch file to see how vocatus accomplishes this
:: Need to swtich away from flags and read from a file instead for the client
:: info. Will be easier to restart one of the stages if something goes sideways.
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