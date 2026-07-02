@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_LANGUAGE="
set "NO_ONBOARD="

if /i "%~1"=="--language" (
    set "PROJECT_LANGUAGE=%~2"
    shift
    shift
)
if /i "%~1"=="--language=ru" set "PROJECT_LANGUAGE=ru" & shift
if /i "%~1"=="--language=en" set "PROJECT_LANGUAGE=en" & shift
if /i "%~1"=="--quick" set "NO_ONBOARD=-NoOnboard"
if /i "%~1"=="--no-onboard" set "NO_ONBOARD=-NoOnboard"

call "%SCRIPT_DIR%lib\i18n.cmd" init

echo !I18N_openclaw_running!
echo.

if defined NO_ONBOARD (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing 'https://openclaw.ai/install.ps1'))) -NoOnboard"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "irm https://openclaw.ai/install.ps1 | iex"
)

set "RC=!ERRORLEVEL!"
if !RC! neq 0 (
    echo.
    echo !I18N_openclaw_failed!
    exit /b !RC!
)

echo.
echo !I18N_openclaw_installed_verify!
exit /b 0
