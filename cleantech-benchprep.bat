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
	title TechTutors - Install Chocolatey and Utils


goto wificonfig

:clientinfo
    :: --- START client_info_entry.bat
        color E0
        echo ------------------------
        echo Please enter client info
        echo ------------------------
        echo,

        :clientname
            set clientnametest=y
            set tac_firstname=
            set tac_lastname=
            set /p firstname="Client's first name: "
            set /p lastname="Client's Last name: "
            echo,

        :clientnameconfirm
            set /p clientnametest="You entered: %tac_firstname% %tac_lastname%. Is this correct? (y/n): "
            rem %=%
            if /i %clientnametest%==y goto clientnamegood
            if /i %clientnametest%==n goto clientname
            echo Incorrect input. & goto clientnameconfirm

        :clientnamegood

:wificonfig
    echo Installing TechTutors Wi-Fi Access...
    netsh wlan add profile filename="Wi-Fi-TechTutors-5G.xml"
    netsh wlan set profileorder name=TechTutors interface=* priority=1
    netsh wlan add profile filename="Wi-Fi-TechTutors.xml"
    netsh wlan set profileorder name=TechTutors interface=* priority=2
    echo,

    echo Connecting to TechTutors Wi-Fi
    netsh connect name=TechTutors ssid=Techtutors
    echo,

:choco
    if not exist "%systemdrive\ProgramData\chocolatey\bin\choco.exe" goto chocoinstall
    choco upgrade all
    goto installapps

    :chocoinstall
    echo Installing Chocolatey...
    echo,

    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%profilesfolder%\Public\chocolatey\bin"
    echo,

    :installapps
    echo,
    echo Installing common utilities and apps...
    choco install -y bonjour googlechrome tightvnc
    echo,
    echo ALL DONE!
    pause

:remoteaccess
    echo,
    echo Configuring remote access (including Safemode)
    reg import remoteaccess.reg

:ttadmin
::test for existence of tt admin user
    net user|findstr /i "techtutors"
    if %errorlevel% EQU 0 echo "Techtutors admin already exists. Skipping..." & goto ttpassgood

:ttadminadd
    net user /add TechTutors
    net localgroup /add administrators TechTutors

:setttpass
    echo,
    echo Setting TechTutors local admin password...
    net user TechTutors *
    echo,

:ttpassgood
    echo TechTutors admin account ready.
    echo,

:hostnametest
    set hostq=y
    set /p hostq="Current hostname is %COMPUTERNAME%. Would you like to change it? (Y/n) "
    echo,
    if /i %hostq%==y goto hostnamechange
    if /i %hostq%==n goto almostdone
    echo "Invalid input. Pleast try again..."
    goto hostnametest    

:hostnamechange
    set newhostname=%COMPUTERNAME%
    set newhostq=n
    set /p newhostname="Please enter a new host-name "
    echo,
    set /p newhostq="You entered %newhostname%, is this correct? (y/N) "
    if /i %newhostq%==y goto newhostname
    if /i %newhostq%==n goto hostnamechange
    echo "Invalid input. Pleast try again..."
    goto hostnamechange

:newhostname
    WMIC computersystem where name='%COMPUTERNAME%' call rename name='%newhostname%'

:firewall
    echo Adding TeamViewer to exeception list
    netsh advfirewall add rule name="TeamViewer TCP" program="C:\Program Files (x86)\TeamViewer\TeamViewer.exe" protocol=tcp dir=in enable=yes action=allow Profile=Private,Public
    netsh advfirewall add rule name="TeamViewer UDP" program="C:\Program Files (x86)\TeamViewer\TeamViewer.exe" protocol=udp dir=in enable=yes action=allow Profile=Private,Public

:almostdone
    echo, "We need to reboot. Let's do that now, mmmKay? Close anything you need before you press another button..."
    echo,
    pause
    shutdown /r /t 0
:end
