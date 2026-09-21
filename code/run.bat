@echo off
cd /d "%~dp0"
if not exist lab1.exe (
    echo Run build.bat first.
    pause
    exit /b 1
)
lab1.exe
pause
