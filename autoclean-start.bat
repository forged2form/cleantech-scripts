rem need to add permissions check
rem test del %homedir%/desktop/techtutors/ command
rem add test for techtemp
rem add test for non null entries
rem check where netletter test went...

@echo off
    color 1f
    mode 90,35
	title TechTutor's Clean Up Script
 
    SETLOCAL EnableDelayedExpansion
	
	cls
	
	set horiz_line=-
	set dash=-
	
	for /L %%i in (0,1,88) do (
		set horiz_line=-!horiz_line!
	)
	
	echo %horiz_line%
	echo TechTutor's Clean Up Script
	echo %horiz_line%
	echo,
	
	:drivelettertest
	for %%d in (a b c d e f g h i j k l m n o p q r s t u v) do (if not exist %%d: echo Beast documents folder will be mapped to: %%d: & set "netletter=%%d:" & goto :netletter)
	
	:netletter
    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )
	
	echo [93mmkdir %HOMEPATH%\Desktop\techtemp[97m
	mkdir %HOMEPATH%\Desktop\techtemp
	rem echo [93mcd %HOMEPATH%\Desktop\techtemp[97m
	rem cd %HOMEPATH%\Desktop\techtemp
	
	set workingdir=c:%HOMEPATH%\Desktop\techtemp
	
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
	echo,

	echo Mapping Beast Documents folder to drive letter %netletter%
	echo,
    echo [93mnet use %netletter% \\BEAST\Documents /user:techtutors *[97m
	net use %netletter% \\BEAST\Documents /user:techtutors *
	echo Network drive mapped to %netletter%
	echo Creating clean up subdirectories for %firstname% %lastname% on the BEAST...
	echo,
	
	echo [93mmkdir "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%"[97m
	mkdir "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%"
	echo ...Done.
	echo,
	
	echo Dumping preclean system info...
	echo [93mmsinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-preclean-%FormattedDate%.nfo"[97m
	msinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-preclean-%FormattedDate%.nfo"
	echo ...Done.
	echo,
	
	echo Copying automation files to %workingdir%
	echo ...Done.
	echo,
	
	echo [93mrobocopy "%netletter%\Automation\Clean Up" %workingdir%[97m
	robocopy "%netletter%\Automation\Clean Up" %workingdir%

    echo Starting Performance Monitor. Please wait... 
	echo,
	
	echo Waiting for perfmon to finish...
    echo [93mtimeout 120[97m
	timeout 120
	echo ...Done!
	echo,
	
	echo [93mlogman import -n TT-CleanUp -xml CleanUp-Test.xml[97m
	logman import -n TT-CleanUp -xml CleanUp-Test.xml
	echo [93mlogman start TT-CleanUp[97m
	logman start TT-CleanUp

    echo Copying Performance Monitor logs...
	
	echo [93mtakeown /f c:\perfmon /r /d y[97m
	takeown /f c:\perfmon /r /d y
	
	echo [93mrobocopy C:\perfmon "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\perfmon" /mir[97m
	robocopy C:\perfmon "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\perfmon" /mir
	echo ...Done!
	echo,
	
	echo Ready to clean up. 
	echo,
	
	pause
	
	echo unpacking tron
	%workingdir%/Tron.exe

	%workingdir%/boottimer.exe
	
 	echo [93mnet use %netletter% /delete[97m
	net use %netletter% /delete
	
	pause
	
	rem   echo [93mrmdir %workingdir%[97m
	rem mdir %workingdir% /s /q
