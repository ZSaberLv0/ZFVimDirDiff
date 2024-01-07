@echo off

for %%i in (%1) do set file0=%%~fi
for %%i in (%2) do set file1=%%~fi

if "%ZFDIRDIFF_IGNORE_SPACE%" == "1" (
    fc /w "%file0%" "%file1%"
) else (
    fc /b "%file0%" "%file1%"
)

