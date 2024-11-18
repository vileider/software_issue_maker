@echo off
title Launch Mouse Button Switcher
echo Starting Mouse Button Switcher...

:: Set path to code directory
set "scriptPath=%~dp0code\MouseSwitcher.ps1"

:: Check if script exists
if not exist "%scriptPath%" (
    echo Error: MouseSwitcher.ps1 not found!
    echo Expected path: %scriptPath%
    echo Please make sure MouseSwitcher.ps1 is in the code folder.
    echo.
    pause
    exit /b
)

:: Run PowerShell script with bypass execution policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%scriptPath%"

:: If PowerShell returns an error
if errorlevel 1 (
    echo.
    echo An error occurred while running the script.
    pause
)

exit /b