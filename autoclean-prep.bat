rem ------------------
rem AUTOCLEAN-PREP.BAT
rem ------------------

rem crappy to do list follows...
rem add test for null entries
rem add test for network connectivity (eth & BEAST access)

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
	title TechTutor's Clean Up Script - Prep Stage
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutor's Clean Up Script - Prep Stage
	echo %horiz_line%
	echo,
	
	set workingdir=c:%HOMEPATH%\Desktop\techtemp
	mkdir %workingdir%
	echo cd %workingdir%
	cd %workingdir%

	echo copy /y NUL autoclean-prep >NUL
	echo,

	copy /y NUL autoclean-prep >NUL
	pause
	
	:drivelettertest
	for %%d in (a b c d e f g h i j k l m n o p q r s t u v) do (if not exist %%d: echo Beast documents folder will be mapped to: %%d: & set "netletter=%%d:" & goto :netletter)
	
	:netletter
    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )

    rem NOTE: Might want to run a command to copy current value...
    echo Turning off UAC temporarily...
    echo Command running: REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
    echo,
	
	:clientname
	echo,
	set input=
	set /p firstname="Client's first name: "
	set /p lastname="Client's Last name: "
	echo,
	:clientnameconfirm
	set /p input=You entered: %firstname% %lastname%. Is this correct? (y/n) %=%
	if /i %input%==y goto :clientnamegood
	if /i %input%==n goto :clientname
	echo Incorrect input. & goto :clientnameconfirm
	
	:clientnamegood
	
	:avira
	echo,
	set av=
	set /p av="Does the client need Avira installed? (y/n): "

	:aviraconfirm
	if /i %av%==y goto :aviraneeded
	if /i %av%==n goto :noavira
	echo Incorrect input. & goto :avira

	:aviraneeded
	set ninite=Ninite Avira Chrome Teamviewer 12 Installer.exe
	goto :netmap

	:noavira
	set ninite=Ninite Chrome Teamviewer 12 Installer.exe

	:netmap
	echo Mapping Beast Documents folder to drive letter %netletter%
	echo,

    echo Command running: net use %netletter% \\BEAST\Documents /user:techtutors *
	net use %netletter% \\BEAST\Documents /user:techtutors *
	echo Network drive mapped to %netletter%
	echo Creating clean up subdirectories for %firstname% %lastname% on the BEAST...
	echo,
	
	echo Command running: mkdir "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%"
	mkdir "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%"
	echo,
	
	echo Dumping preclean system info...
	echo Command running: msinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-preclean-%FormattedDate%.nfo"
	msinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-preclean-%FormattedDate%.nfo"
	echo,
	
	echo Copying automation files to %workingdir%
	echo,
	echo Command running: robocopy /s "%netletter%\Automation\Clean Up" %workingdir%
	robocopy /s "%netletter%\Automation\Clean Up" %workingdir%

	echo Importing perfmon xml...
	echo logman import -n TT-CleanUp -xml CleanUp-Test.xml
	echo,
	logman import -n TT-CleanUp -xml CleanUp-Test.xml

    echo Starting Performance Monitor. Please wait...
	echo,
	
	echo Command running: logman start TT-CleanUp
	logman start TT-CleanUp

	echo Waiting for perfmon to finish...
    echo timeout 120
	timeout 120

	echo Adding next stage to Startup...
	echo Command running: %workingdir%\autoclean-startclean.bat %lastname% %firstname% %FormattedDate% %ninite%>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"
	%workingdir%\autoclean-startclean.bat %lastname% %firstname% %FormattedDate% %ninite%>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"

	rem Removing autoclean-start flag file
	echo Command running: del autoclean-prep
	echo,
	del autoclean-prep
	rem NOTE: Need to check how to automatically log the number that gets presented in the BootTimer dialogue. (Does it output to STDERR?)

	echo Starting BootTimer. Prepare for reboot...
	echo Command running: %workingdir%/boottimer.exe
	echo,
	%workingdir%/boottimer.exe