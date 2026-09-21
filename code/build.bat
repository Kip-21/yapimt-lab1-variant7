@echo off
setlocal
cd /d "%~dp0"
where ml.exe >nul 2>nul
if errorlevel 1 (
    echo Open x86 Native Tools Command Prompt for Visual Studio first.
    exit /b 1
)
ml /nologo /c /coff /Zi main.asm
if errorlevel 1 exit /b 1
link /nologo /subsystem:console /machine:x86 /debug /out:lab1.exe main.obj kernel32.lib
if errorlevel 1 exit /b 1
echo Built lab1.exe
