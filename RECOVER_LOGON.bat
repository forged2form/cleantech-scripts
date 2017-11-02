@Echo off

:: Recovery batch file for auto-login failures during Tron stage of CleanTech

echo Resetting explorer registry entry
echo,
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d explorer.exe /f
if %ERRORLEVEL% NEQ 1 echo done!
else echo Houston, we have a problem! Report this to Tim!
echo,
echo Press any key to restart...
pause
shutdown /r /t 0
:end