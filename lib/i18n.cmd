@echo off
:: Project i18n loader for CMD scripts
:: Usage: call "%SCRIPT_DIR%lib\i18n.cmd" init
:: Requires: SCRIPT_DIR, optional PROJECT_LANGUAGE (ru|en|auto)

if /i not "%~1"=="init" exit /b 1

chcp 65001 >nul 2>&1

set "I18N_SCRIPT_DIR=%SCRIPT_DIR%"
if "%I18N_SCRIPT_DIR:~-1%"=="\" set "I18N_SCRIPT_DIR=%I18N_SCRIPT_DIR:~0,-1%"

set "I18N_EXPORT_TEMP=%TEMP%\proj_i18n_%RANDOM%.txt"
set "I18N_CLI_OVERRIDE="
if defined PROJECT_LANGUAGE set "I18N_CLI_OVERRIDE=%PROJECT_LANGUAGE%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0i18n-export.ps1" -ScriptDir "%I18N_SCRIPT_DIR%" -CliOverride "%I18N_CLI_OVERRIDE%" -OutFile "%I18N_EXPORT_TEMP%" 2>nul
if not exist "%I18N_EXPORT_TEMP%" exit /b 1

for /f "usebackq tokens=1,* delims==" %%a in ("%I18N_EXPORT_TEMP%") do (
    call :set_i18n_var "%%a" "%%b"
)

del "%I18N_EXPORT_TEMP%" >nul 2>&1
exit /b 0

:set_i18n_var
setlocal DisableDelayedExpansion
set "_K=%~1"
set "_V=%~2"
for %%G in ("%_K%=%_V%") do endlocal & set %%G
exit /b 0
