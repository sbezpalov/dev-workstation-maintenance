@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT=%~dp0maintain-dev-workstation.cmd"
set "SCRIPT_DIR=%~dp0"
set "TASK_NAME=DevWorkstationMaintenance"

call "%SCRIPT_DIR%lib\i18n.cmd" init

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo !I18N_register_need_admin!
    exit /b 1
)

schtasks /Create /TN "%TASK_NAME%" /TR "\"%SCRIPT%\"" /SC MONTHLY /D 1 /ST 09:00 /RL HIGHEST /F

if %ERRORLEVEL% neq 0 (
    echo !I18N_register_failed!
    exit /b 1
)

echo !I18N_register_created!
echo !I18N_register_run_manual!
exit /b 0
