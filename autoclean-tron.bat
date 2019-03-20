:: ------------------
:: Autoclean-Tron.bat
:: ------------------

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
color 1f
mode 100,35
title CleanTech - Tron

SETLOCAL EnableDelayedExpansion

cls

set horiz_line=-
set dash=-

for /L %%i in (0,1,88) do (
	set horiz_line=-!horiz_line!
)

echo %horiz_line%
echo CleanTech - Tron Stage
echo %horiz_line%
echo,

set "tac_workingdir=C:\CleanTechTemp"
echo cd "C:\CleanTechTemp"
cd "C:\CleanTechTemp"

tac_debugmode=rem nothing to see here

echo Printing Last run variables:
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do echo %%i
for /f "delims=" %%i in (%tac_workingdir%\CT-Flags.txt) do set %%i

::tron done test
if !tac_step!==trondone (
	color 4f
	echo,
	echo It appears that you've already completed this step.
	echo Please relaunch from autoclean-launcher.bat.
	echo If you think you are seeing this in error
	echo please contact tech support. :P
	echo Press a key to exit...
	echo,
	pause
	exist
)

if NOT !tac_step!==startcleandone (
	echo Resuming from step:!tac_step!
	pause
	goto !tac_step!
)

:tronstart
	set tac_step=tronstart
	set tac_>%tac_workingdir%\CT-Flags.txt

:echostrings
	set tac_step=echostrings
	set tac_>%tac_workingdir%\CT-Flags.txt

	color E0
	echo -----------------------
	echo Client Info:
	echo Last Name: %tac_lastname%
	echo First name: %tac_firstname%
	echo Date: %tac_FormattedDate%
	echo AV needed?:
	echo Offline?: 
	echo -----------------------
	echo,

color 1f

	:: echo "Command running: REG IMPORT /f "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\PreStartClean-Winlogon.reg""
	:: REG IMPORT /f "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%tac_clientdir%\PreStartClean-Winlogon.reg" /f

:starttron
	set tac_step=starttron
	set tac_>%tac_workingdir%\CT-Flags.txt

	echo Starting Tron...
	start /wait %tac_workingdir%\Tron\tron\Tron.bat -a -str -sdc
	echo,

:: THIS IS NOT WORKING AS INTENDED RIGHT NOW -- if NOT exist "%tac_workingdir%\Tron\tron\resources\tron_stage.txt" (

:didtronfinish
:: create prompt to see if tron finished OR test via trons own error / logs if possible

:nir
	set tac_step=nir
	set tac_>%tac_workingdir%\CT-Flags.txt

	::might not be needed. can easily start with Ctl-Alt-Del
	::%tac_workingdir%\nircmd\nircmd.exe win min process explorer.exe

:reboot-prep
echo Ensuring next boot is in normal mode...
echo bcdedit /deletevalue {default} safeboot
bcdedit /deletevalue {default} safeboot
echo,

:putshellback

	:: Why is this here?
	::"C:\Program Files (x86)\TeamViewer\TeamViewer.exe" &

	echo Command running: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
	%tac_debugmode%

	::Restoring user's original login settings
	echo Removing AutoLogon
	echo Command running: "REG IMPORT "%tac_clientdir%\Preclean-Winlogon.reg""
	REG IMPORT "%tac_clientdir%\Preclean-Winlogon.reg"

:trondone
	color 4f
	set tac_step=trondone
	set tac_stage=finish
	set tac_>%tac_workingdir%\CT-Flags.txt
	echo "Press a key to restart...."
	pause
	shutdown /r /t 0