@echo off
setlocal EnableExtensions

:: Registers a monthly scheduled task (requires Run as Administrator once).
:: Uses schtasks — no PowerShell dependency.

set "SCRIPT=%~dp0maintain-dev-workstation.cmd"
set "TASK_NAME=DevWorkstationMaintenance"

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Run this script as Administrator to register the scheduled task.
    exit /b 1
)

schtasks /Create /TN "%TASK_NAME%" /TR "\"%SCRIPT%\"" /SC MONTHLY /D 1 /ST 09:00 /RL HIGHEST /F

if %ERRORLEVEL% neq 0 (
    echo Failed to create scheduled task.
    exit /b 1
)

echo Scheduled task "%TASK_NAME%" created — runs on the 1st of each month at 09:00.
echo To run manually: schtasks /Run /TN "%TASK_NAME%"
exit /b 0
