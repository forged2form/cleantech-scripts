rem --------------------
rem AUTOCLEAN-FINISH.BAT
rem --------------------
rem test del %homedir%/desktop/techtutors/ command

set workingdir=C:\%USERPATH%\Desktop\techtemp\
echo cd %workingdir% 
cd %workingdir%

	set lastname=%1
	set firstname=%2
	set FormattedDate=%3
	echo Testing strings...
	echo Last Name: %lastname%
	echo First name: %firstname%
	echo Date: %FormattedDate%
	echo,

echo copy /y NUL autoclean-finish >NUL
echo,
copy /y NUL autoclean-finish >NUL

@echo off
:: BatchGotAdmin 
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
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
    mode 90,35
	title CleanTech - Wrap Up
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo CleanTech - Wrap Up
	echo %horiz_line%
	echo,

	echo Setting client-info variables
	set lastname=%1
	set firstname=%2
	set FormattedDate=%3
	set ninite=%4
	echo Testing strings...
	echo Last Name: %lastname%
	echo First name: %firstname%
	echo Date: %FormattedDate%
	echo,

	title CleanTech: Installing/Updating Utils
	echo Command running: START "" /WAIT "%workingdir%\%ninite%"
	START "" /WAIT "%workingdir%\%ninite%"
	echo,

	title CleanTech: Performance Test #2

	echo Starting Performance Monitor. Please wait... 
	echo,
	
	echo logman start TT-CleanUp
	logman start TT-CleanUp

	echo Waiting for perfmon to finish...
    echo timeout 120
	timeout 120
	echo ...Done!
	echo,

    echo Copying Performance Monitor logs...
	
	echo Command running: takeown /f c:\perfmon /r /d y
	takeown /f c:\perfmon /r /d y
	
	echo robocopy /s C:\perfmon "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\perfmon" /mir
	robocopy /s C:\perfmon "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\perfmon" /mir
	echo ...Done!
	echo,
	
	title CleanTech: Moving Log Files
	echo Moving Log files
	echo,
	
	echo Command running: move C:\Logs "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\"
	move C:\Logs "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\"

	echo Command running: move C:\ADW move C:\Adw "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\Logs\"
	move C:\ADW move C:\ADW "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\Logs\"

	title CleanTech: Removing Cleanup Files
	echo Removing cleanup files...
	echo,

	echo Command running: logman delete import -n TT-CleanUp
	logman delete -n TT-CleanUp
	echo,

	echo Dumping postclean system info...
	echo Command running: msinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-postclean-%FormattedDate%.nfo"
	msinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-postclean-%FormattedDate%.nfo"
	echo,

	echo Turning UAC back on...
    echo Command running: REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    echo,
    REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f
	
	echo Command running: rmdir %workingdir%
	rmdir %workingdir% /s /q