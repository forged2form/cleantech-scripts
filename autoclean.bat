rem need to add permissions check
rem test del %homedir%/desktop/techtutors/ command
rem add test for techtemp
rem add test for non null entries
rem check where netletter test went...

@echo off
    color 1f
    mode 90,40
 
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
	
	set netletter=t:
	echo Network drive mapped to %netletter%
	echo,

    for /f "skip=1 tokens=1-6 delims= " %%a in ('wmic path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') do (
        IF NOT "%%~f"=="" (
            set /a FormattedDate=10000 * %%f + 100 * %%d + %%a
            set FormattedDate=!FormattedDate:~-0,4!-!FormattedDate:~-4,2!-!FormattedDate:~-2,2!
        )
    )
	
	echo [93mmkdir %HOMEPATH%\Desktop\TechTEMP[97m
	echo [93mcd %HOMEPATH%\Desktop\TechTEMP[97m
	
	set /p firstname="Client's first name: "
	set /p lastname="Client's Last name: "
	echo,
	
	REM Need to add drive map check at outset of script. (See ex. WinReducer.pl)
	
	echo Mapping Beast Documents folder to drive letter %netletter%
	echo,
    echo [93mnet use %netletter% \\BEAST\Documents /user:techtutors *[97m
	echo Creating clean up subdirectories for %firstname% %lastname% on the BEAST...
	echo,
	
	echo [93mmkdir "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%"[97m
	echo ...Done.
	echo,
	
	echo Dumping preclean system info...
	echo [93mmsinfo32 /nfo "%netletter%\Sysinfo Dumps\%lastname%-%firstname%-preclean-%FormattedDate%.nfo"[97m
	echo ...Done.
	echo,
	
	echo Copying automation files to %cd%
	echo ...Done.
	echo,
	
	echo [93mrobocopy "%netletter%\Automation\Clean Up" %cd%[97m

    echo Starting Performance Monitor. Please wait... 
	echo,
	
	echo Waiting for perfmon to finish...
    echo [93mtimeout 70[97m
	echo ...Done!
	echo,
	
	echo [93mlogman import -n TT-CleanUp -xml CleanUp-Test.xml[97m
	echo [93mlogman start TT-CleanUp[97m

    echo Copying Performance Monitor logs...
	
	echo [93mcopy C:\perfmon "%netletter%\Clean Up Logs\%lastname%-%firstname%-%FormattedDate%\perfmon"[97m
	echo ...Done!
	echo,
	
	echo Ready to clean up. 
	echo,
	
	pause

    echo [93mcd %homedir%[97m
    echo [93mdel %homedir%\desktop\techtemp[97m

	echo [93mnet use %netletter% /delete[97m
	
	pause
