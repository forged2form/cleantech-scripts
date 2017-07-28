µ:: ------------------
:: AUTOCLEAN-PREP.BAT
:: ------------------

:: crappy to do list follows...
:: SYSTEM BEEP AT TIMES OF INPUT
:: add test for null entries
:: add test for network connectivity (eth & BEAST access)
:: look into ability to drag and drop text file or csv with client data,
:: (e.g. name, av needed, password)
:: Should log start time of each script (really, of each command)
::     - Observe logwithdate batch file to see how vocatus accomplishes this
:: Need to swtich away from flags and read from a file instead for the client
:: info. Will be easier to restart one of the stages if something goes sideways.

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
	title CleanTech - Prep Stage
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo CleanTech - Prep Stage
	echo %horiz_line%
	echo,

	:initializeVars
		set netletter=
		set lastname=
		set firstname=
		set input=
		set av=
		set chillout=rem nothing to see here

		if defined %1 set chillout=%1 else goto:drivelettertest
	
	:drivelettertest
	for %%d in (a b c d e f g h i j k l m n o p q r s t u v) do (if not exist %%d: echo Beast documents folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto :netletter)
	
	:netletter
    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )
	
	:clientinfo
		color E0
		echo ------------------------
		echo Please enter client info
		echo ------------------------
		echo,

		:clientname
			set input=
			set /p firstname="Client's first name: "
			set /p lastname="Client's Last name: "
			echo,

		:clientnameconfirm
			set /p input="You entered: %firstname% %lastname%. Is this correct? (y/n): "
			rem %=%
			if /i %input%==y goto :clientnamegood
			if /i %input%==n goto :clientname
			echo Incorrect input. & goto :clientnameconfirm

		:clientnamegood

		:checkautologin
			set autoadminlogonenabled=0
			reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon | find "1"
			if %ERRORLEVEL% EQU 0 (set autoadminlogonenabled=1 & echo autoadminlogonenabled=!autoadminlogonenabled! & goto :avira) || goto :passquestion
			pause

		:passquestion
			set /p passq="Does the the current user (%USERNAME%) require a password? (y/n): "
			if /i %passq%==y goto :passwordneeded
			if /i %passq%==n goto :avira
			echo Incorrect input. & goto :passquestion

		:passwordneeded
			set /p password="Please enter the password for %USERNAME%: "
			if /i %password%=="" echo You didn't enter anything! *Sigh* Try again... & goto :passwordneeded

			:passconfirm
			echo You entered: %password%
			set passconfirm=
			set /p passconfirm="Is this correct? (y/n): "

			if /i %passconfirm%==y goto :avira
			if /i %passconfirm%==n goto :passwordneeded
			echo Incorrect input. & goto :passconfirm
	
		:avira
			echo,
			set av=
			set /p av="Does the client need Avira installed? (y/n): "

		:aviraconfirm
			if /i %av%==y goto :netmap
			if /i %av%==n goto :netmap
			echo Incorrect input. & goto :avira

	:netmap
		echo Mapping Beast Documents folder to drive letter %netletter%
		echo,

    	echo Command running: net use %netletter% \\BEAST\Documents /user:techtutors *
		net use %netletter% \\BEAST\Documents /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto :netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%
		echo Creating clean up subdirectories for %firstname% %lastname% on the BEAST...
		echo,

	:cleanupfilesprep
		set "workingdir=c:%HOMEPATH%\Desktop\CleanTechTemp"
		mkdir %workingdir%
		echo cd %workingdir%
		cd %workingdir%
		set "clientdir=%workingdir%\%lastname%-%firstname%-%FormattedDate%"

		echo copy /y NUL autoclean-prep >NUL
		echo,

		copy /y NUL autoclean-prep >NUL
		%chillout%

		echo Copying automation files to %workingdir%
		echo,
		echo Command running: robocopy "%netletter%\Automation\Clean Up" %workingdir% /XD "*.sync" /s
		robocopy "%netletter%\Automation\Clean Up" %workingdir% /XD "*.sync" /s

		echo Command running: mkdir %clientdir%
		mkdir %clientdir%
		echo,

	:maxwindow
		%workingdir%/nircmd/nircmd.exe win max ititle "CleanTech - Prep Stage"

	:disableav
		color 4f
		echo IMPORTANT
		echo -----------------------------------------------------------------------
		echo Please check for running av and disable real-time features temporarily.
		echo Press any key when you've finished to continue.
		echo -----------------------------------------------------------------------
		echo Command running: %workingdir%\securitysoftview\SecuritySoftView.exe
		call %workingdir%\securitysoftview\SecuritySoftView.exe
		%chillout%

	:registryprep

		:restorepoint
			echo Creating Pre-Clean restore point...
			reg export "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" %clientdir%\PreClean-SystemRestore.reg
			reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /t reg_dword /v SystemRestorePointCreationFrequency /d 0 /f >nul 2>&1
			powershell "Enable-ComputerRestore -Drive "%SystemDrive%""
			powershell "Checkpoint-Computer -Description 'CleanTech: Pre-Clean checkpoint'"
			%chillout%
			
		:uac
			echo Saving current UAC values

			IF EXIST "%clientdir%\Preclean-Policies_System.reg" goto :uac-reg

			:policies-system
				REG EXPORT HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System %clientdir%\Preclean-Policies_System.reg
				echo,

			:uac-reg
			    echo Turning off UAC temporarily...
			    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
			    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
			    echo,

		    
		:autologon
		    echo Saving current AutoLogon values
		    IF EXIST "%clientdir%\Preclean-Winlogon.reg" goto :autologoncheck
		    echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		    %chillout%
		    echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\Preclean-Winlogon.reg"
		    REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\Preclean-Winlogon.reg"
		    echo,
		    %chillout%

			:autologoncheck
		    	if /i %autoadminlogonenabled%==1 goto :systeminfo

		    :setautologin
			    echo Setting autologin for CleanTech session...
			   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d %USERNAME% /f
			   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d %PASSWORD% /f
			   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
			    echo,

	:systeminfo
		echo Dumping preclean system info...
		echo Command running: msinfo32 /nfo "%clientdir%\%lastname%-%firstname%-preclean-systeminfo-%FormattedDate%.nfo"
		msinfo32 /nfo "%clientdir%\%lastname%-%firstname%-preclean-systeminfo-%FormattedDate%.nfo"
		echo,

		echo Pre-emptively rebuilding performance counters
		echo Command running: lodctr /r
		lodctr /r
		echo,

		echo Importing perfmon xml...
		echo logman import -n CleanTech-PreCleanTest -xml Perfmon-Pre.xml
		echo,
		logman import -n CleanTech-PreCleanTest -xml Perfmon-Pre.xml

	    echo Starting Performance Monitor. Please wait...
		echo,
		
		echo Command running: logman start CleanTech-PreCleanTest
		logman start CleanTech-PreCleanTest

		echo Waiting for perfmon to finish...
	    echo timeout 120
		timeout 120
		color E0 & %chillout% & color 1f

	:nextstageprep
		echo Adding next stage to Startup...
		echo Command running: echo %workingdir%\autoclean-startclean.bat %lastname% %firstname% %FormattedDate% %ninite%>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"
		echo %workingdir%\autoclean-startclean.bat %lastname% %firstname% %FormattedDate% %av%>"C:%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"

		:: Removing autoclean-start flag file
		echo Command running: del autoclean-prep
		echo,
		del autoclean-prep
		:: NOTE: Need to check how to automatically log the number that gets presented in the BootTimer dialogue. (Does it output to STDERR?)

		echo Starting BootTimer. Prepare for reboot...
		echo Command running: %workingdir%\boottimer.exe
		echo,
		start %workingdir%\boottimer.exe
		%workingdir%\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes
		shutdown /r /t 0