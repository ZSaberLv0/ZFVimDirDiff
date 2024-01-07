@echo off

for %%i in (%1) do set file0=%%~fi

dir /b /a-d "%file0%" 2>nul
exit /b 0

