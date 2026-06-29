@echo off
setlocal EnableExtensions

:: Official OpenClaw installer — same as:
::   powershell -c "irm https://openclaw.ai/install.ps1 | iex"
::
:: Options:
::   install-openclaw.cmd           full install + onboarding
::   install-openclaw.cmd --quick   install only, skip onboarding

set "NO_ONBOARD="
if /i "%~1"=="--quick" set "NO_ONBOARD=-NoOnboard"
if /i "%~1"=="--no-onboard" set "NO_ONBOARD=-NoOnboard"

echo Running official OpenClaw installer...
echo.

if defined NO_ONBOARD (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing 'https://openclaw.ai/install.ps1'))) -NoOnboard"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "irm https://openclaw.ai/install.ps1 | iex"
)

set "RC=%ERRORLEVEL%"
if %RC% neq 0 (
    echo.
    echo Install failed with exit code %RC%. See output above.
    exit /b %RC%
)

echo.
echo OpenClaw installed. Verify: openclaw --version
exit /b 0
