@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1

set "SCRIPT_DIR=%~dp0"
set "PROJECT_LANGUAGE="
set "PS_ARGS="
set "PAUSE_ON_EXIT=0"
set "SHOW_HELP=0"
set "ARG_ERROR="

:parse_args
set "ARG=%~1"
if not defined ARG goto :args_done

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
if /i "!ARG!"=="--pause" (
    set "PAUSE_ON_EXIT=1"
    shift
    goto :parse_args
)
if /i "!ARG!"=="--language" goto :read_language
if /i "!ARG!"=="-Language" goto :read_language
if /i "!ARG:~0,11!"=="--language=" (
    set "PROJECT_LANGUAGE=!ARG:~11!"
    set "PS_ARGS=!PS_ARGS! -Language "!PROJECT_LANGUAGE!""
    shift
    goto :parse_args
)

set "PS_ARGS=!PS_ARGS! "!ARG!""
shift
goto :parse_args

:read_language
if "%~2"=="" (
    set "ARG_ERROR=!ARG! requires a value"
    goto :args_done
)
set "PROJECT_LANGUAGE=%~2"
set "PS_ARGS=!PS_ARGS! -Language "!PROJECT_LANGUAGE!""
shift
shift
goto :parse_args

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
    echo !I18N_launcher_usage!
    echo !I18N_launcher_options!
    echo !I18N_launcher_pause!
    echo.
    exit /b 0
)

echo !I18N_launcher_start!
echo !I18N_launcher_options!
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%clean_disk.ps1" !PS_ARGS!
set "RC=!ERRORLEVEL!"

if "!PAUSE_ON_EXIT!"=="1" pause
exit /b !RC!
