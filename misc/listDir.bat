@echo off

for %%i in (%1) do set file0=%%~fi

dir /b /ad "%file0%"

