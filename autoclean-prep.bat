:: @echo off

:: ------------------
:: AUTOCLEAN-PREP.BAT
:: ------------------

:: Crappy to do list follows...
:: Look into Task Manager vs. StartupTool (Nirsoft) - REQ from Will
:: In flag file, create last command name for restarting
:: 			(ie: if %6 then set lastcommand = %6)
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
		set av=n
		set debugmode=no
		set offline=no
		set debugmode=rem

		if defined %1 (set "debugmode=pause" & set "debugmode=pause") else (goto:drivelettertest)

	:::offlineset
	::set offline=
	::set /p offline="Would you like to work offline? (y/n]) "
	::	if /i %offline%==y (set "offline=yes" & goto :clientinfo)
	::	if /i %offline%==n (set "offline=no" & goto :drivelettertest)
	::	echo Incorrect input. & goto :offlineset

    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )

    :: Prep for 'speed-mode' - rudimentary -- FIXME!
    :speedmode
    set speedmode=
    set /p speedmode="Would you like to speed things up? (y/n) "
	if /i %speedmode%==y goto :hibernateoff
	if /i %speedmode%==n goto :clientinfo
	goto :speedmode

	:hibernateoff
	powercfg /hibernate off

    :clientinfo
	:: --- START client_info_entry.bat
		color E0
		echo ------------------------
		echo Please enter client info
		echo ------------------------
		echo,

		:clientname
			set input=
			set firstname=
			set lastname=
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
			if %ERRORLEVEL% EQU 0 (set autoadminlogonenabled=1 & echo autoadminlogonenabled=!autoadminlogonenabled! & goto :av) || goto :av REM skipping autologin prompts
			pause

		:passquestion
			set password=
			set /p passq="Does the the current user (%USERNAME%) require a password? (y/n): "
			if /i %passq%==y goto :passwordneeded
			if /i %passq%==n goto :av
			echo Incorrect input. & goto :passquestion

		:passwordneeded
			set /p password="Please enter the password for %USERNAME%: "
			if /i %password%=="" echo You didn't enter anything! *Sigh* Try again... & goto :passwordneeded

			:passconfirm
			echo You entered: %password%
			set passconfirm=
			set /p passconfirm="Is this correct? (y/n): "

			if /i %passconfirm%==y goto :passcorrect
			if /i %passconfirm%==n goto :passwordneeded
			echo Incorrect input. & goto :passconfirm
			:passcorrect
	
		:av
			echo,
			set av=n
			:: REPLACE with TrendMicro eventually
			:: set /p av="Does the client need av installed? (y/n): "

		:avconfirm
			if /i %av%==y goto :drivelettertest
			if /i %av%==n goto :drivelettertest
			echo Incorrect input. & goto :av
	:: --- END client_info_entry.bat

	:: --- START map_beast.bat
	:drivelettertest
	for %%d in (h i j k l m n o p q r s t u v) do (if not exist %%d: echo Beast Utilities folder will be mapped to: %%d: & set "netletter=%%d:" & echo, & goto :netmap)
	
	if offline==y goto :cleanupfilesprep
	:netmap
		echo Mapping Beast Utilities folder to drive letter %netletter%
		echo,

    	echo Command running: net use %netletter% \\BEAST\Utilities /user:techtutors *
		net use %netletter% \\BEAST\Utilities /p:no /user:techtutors * 
		if errorlevel 1 echo That didn't seem to work. Try again... & goto :netmap
		echo,

		color 1f
		echo Network drive mapped to %netletter%
    :: --- END map_beast.bat

    :: --- START cleanupfilesprep.bat
	:cleanupfilesprep
		echo Creating local clean up subdirectories for %firstname% %lastname%
		echo,

		set "workingdir=C:\CleanTechTemp"
		mkdir "C:\CleanTechTemp"
		echo cd "C:\CleanTechTemp"
		cd "C:\CleanTechTemp"
		set "clientdir=C:\CleanTechTemp\%lastname%-%firstname%-%FormattedDate%"

		:: Setting flag file
		echo Command running: copy /y NUL autoclean-prep >NUL
		echo,

		copy /y NUL autoclean-prep >NUL
		%debugmode%

		echo Copying automation files to C:\CleanTechTemp
		echo,
		echo Command running: robocopy "%netletter%\Clean Up" "C:\CleanTechTemp" /XD "*.sync" /s
		robocopy "%netletter%\Clean Up" "C:\CleanTechTemp" /XD "*.sync" /s

		echo Command running: mkdir "%clientdir%"
		mkdir "%clientdir%"
		echo,

			:disableav
			color 4f
			echo IMPORTANT
			echo -----------------------------------------------------------------------
			echo Please check for running av and disable real-time features temporarily.
			echo You'll need to ensure that it will be in passive mode throughout reboots.
			echo Press any key when you've finished to continue.
			echo -----------------------------------------------------------------------
			echo Command running: "C:\CleanTechTemp\securitysoftview\SecuritySoftView.exe"
			call "C:\CleanTechTemp\securitysoftview\SecuritySoftView.exe"
			%debugmode%
		:: --- END cleanupfilesprep.bat

			color 1f

	:maxwindow
		"C:\CleanTechTemp\nircmd\nircmd.exe" win max ititle "CleanTech - Prep Stage"

	:: --- START reg_backup.bat
	:registrybackup
		reg export "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" "%clientdir%\PreClean-SystemRestore.reg"

		:uacbackup
			echo Saving current UAC values

			REM safety code incase we aprubtly closed or crashed... Don't want to overwrite client's original registry entries
			IF EXIST "%clientdir%\Preclean-Policies_System.reg" goto :uac-reg

			:policies-system
				REG EXPORT HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System "%clientdir%\Preclean-Policies_System.reg"
				echo,
		    
		:autologon
		    echo Saving current AutoLogon values
		    IF EXIST "%clientdir%\Preclean-Winlogon.reg" goto :autologoncheck
		    echo reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		    %debugmode%
		    echo REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\Preclean-Winlogon.reg"
		    REG EXPORT "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "%clientdir%\Preclean-Winlogon.reg"
		    echo,
		    %debugmode%
	    :: --- END reg_backup.bat

	    :: --- START reg_prepmode_changes.bat
	    :uac-reg
			    echo Turning off UAC temporarily...
			    echo Command running: REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
			    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
			    echo,

		:restorepoint
			echo Creating Pre-Clean restore point...
			reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /t reg_dword /v SystemRestorePointCreationFrequency /d 0 /f >nul 2>&1
			powershell "Enable-ComputerRestore -Drive "%SystemDrive%""
			powershell "Checkpoint-Computer -Description 'CleanTech: Pre-Clean checkpoint'"
			%debugmode%
		:: --- END reg_prepmode_changes.bat

		:: --- START techtutors_admin_account_create.bat
		:createttadmin
		:: Creating Tech Tutors admin accout to avoid PIN-based autologin issues and ot aid in recovery in case things go cataclysmic
		echo net user /add techtutors
		net user /add techtutors
		echo net localgroup administrators /add techtutors
		net localgroup administrators /add techtutors
		:: --- END techtutors_admin_account_create.bat
		
			REM :autologoncheck
		    REM	if /i %autoadminlogonenabled%==1 goto :systeminfo

	REM skipping due to current bugs	    :setautologin
	rem		    echo Setting autologin for CleanTech session...
	rem		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d %USERNAME% /f
	REM		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d %PASSWORD% /f
	REM		   	REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
	REM		    echo,

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
	    echo timeout 330
		timeout 330
		color E0 & %debugmode% & color 1f

	:nextstageprep
		echo Adding flags to text file
		echo "Prep Flags = Last name: %lastname% , First name: %firstname% , Date: %FormattedDate% , Ninite: %ninite% , Debugmode: %debugmode% , Offline: %offline%" > C:\CT-flags.text
		echo,
		echo Adding next stage to Startup...
		echo Command running: echo "C:\CleanTechTemp\autoclean-startclean.bat" %lastname% %firstname% %FormattedDate% %ninite% %debugmode% %offline%>"%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"
		echo "C:\CleanTechTemp\autoclean-startclean.bat" %lastname% %firstname% %FormattedDate% %av% %debugmode% %offline%>"%HOMEPATH%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\autoclean-startcleantemp.bat"

		echo Command running: del autoclean-prep
		echo,
		del autoclean-prep
		:: NOTE: Need to check how to automatically log the number that gets presented in the BootTimer dialogue. (Does it output to STDERR?)

		:: --- START boottimer_1-1_pre.bat
		echo Starting BootTimer. Prepare for reboot...
		echo Command running: "C:\CleanTechTemp\boottimer.exe"
		echo,
		start C:\CleanTechTemp\boottimer.exe
		echo press any key when you're ready for stage 2
		pause,
		:: C:\CleanTechTemp\nircmd\nircmd.exe dlg "BootTimer.exe" "" click yes <-- NOT WORKING?!?
		shutdown /r /t 0
		:: --- END boottimer_1-1_pre.bat