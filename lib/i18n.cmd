@echo off
:: Project i18n loader for CMD scripts
:: Usage: call "%SCRIPT_DIR%lib\i18n.cmd" init
:: Requires: SCRIPT_DIR, optional PROJECT_LANGUAGE (ru|en|auto)
::
:: Applies translations via a generated .cmd with caret-escaped ! so
:: placeholders like !PKG_NAME! survive the caller's EnableDelayedExpansion.

if /i not "%~1"=="init" exit /b 1

chcp 65001 >nul 2>&1

set "I18N_SCRIPT_DIR=%SCRIPT_DIR%"
if "%I18N_SCRIPT_DIR:~-1%"=="\" set "I18N_SCRIPT_DIR=%I18N_SCRIPT_DIR:~0,-1%"

set "I18N_APPLY_TEMP="
set "I18N_CLI_OVERRIDE="
if defined PROJECT_LANGUAGE set "I18N_CLI_OVERRIDE=%PROJECT_LANGUAGE%"

for /f "delims=" %%F in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0i18n-export.ps1" -ScriptDir "%I18N_SCRIPT_DIR%" -CliOverride "%I18N_CLI_OVERRIDE%" -ApplyDirectory "%TEMP%" 2^>nul') do set "I18N_APPLY_TEMP=%%F"
if not exist "%I18N_APPLY_TEMP%" exit /b 1

call "%I18N_APPLY_TEMP%"
del "%I18N_APPLY_TEMP%" >nul 2>&1
exit /b 0
