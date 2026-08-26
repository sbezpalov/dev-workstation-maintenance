@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_LANGUAGE="
set "NO_ONBOARD="
set "SHOW_HELP=0"
set "ARG_ERROR="

:parse_args
set "ARG=%~1"
if not defined ARG goto :args_done

if /i "!ARG!"=="--language" (
    if "%~2"=="" (
        set "ARG_ERROR=--language requires a value"
        goto :args_done
    )
    set "PROJECT_LANGUAGE=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!ARG:~0,11!"=="--language=" (
    set "PROJECT_LANGUAGE=!ARG:~11!"
    shift
    goto :parse_args
)
if /i "!ARG!"=="--quick" (
    set "NO_ONBOARD=-NoOnboard"
    shift
    goto :parse_args
)
if /i "!ARG!"=="--no-onboard" (
    set "NO_ONBOARD=-NoOnboard"
    shift
    goto :parse_args
)
if /i "!ARG!"=="--help" (
    set "SHOW_HELP=1"
    shift
    goto :parse_args
)
if /i "!ARG!"=="-h" (
    set "SHOW_HELP=1"
    shift
    goto :parse_args
)

set "ARG_ERROR=Unknown option: !ARG!"

:args_done

call "%SCRIPT_DIR%lib\i18n.cmd" init
if !ERRORLEVEL! neq 0 (
    echo [error] Failed to initialize localization.
    exit /b 1
)

if defined PROJECT_LANGUAGE (
    set "LANGUAGE_VALID=0"
    for %%L in (en ru auto) do if /i "!PROJECT_LANGUAGE!"=="%%L" set "LANGUAGE_VALID=1"
    if "!LANGUAGE_VALID!"=="0" set "ARG_ERROR=Invalid language: !PROJECT_LANGUAGE! (expected en, ru, or auto)"
)

if defined ARG_ERROR (
    echo [error] !ARG_ERROR!
    exit /b 2
)

if "!SHOW_HELP!"=="1" (
    echo.
    echo !I18N_openclaw_usage!
    echo.
    exit /b 0
)

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
