@echo off
:: Initialize the Visual Studio environment (for ml64, link, etc.)
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

:: Assemble
ml64 /c winapi_snake.asm
if errorlevel 1 pause & exit /b

:: Link
link winapi_snake.obj /subsystem:console /entry:main kernel32.lib user32.lib
if errorlevel 1 pause & exit /b

:: Run
winapi_snake.exe
pause


