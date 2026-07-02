@echo off
chcp 65001 > nul
set "SCRIPT_DIR=%~dp0"
set "PROJECT_LANGUAGE="
if /i "%~1"=="--language" (
    set "PROJECT_LANGUAGE=%~2"
    shift
    shift
)
call "%SCRIPT_DIR%lib\i18n.cmd" init
echo !I18N_launcher_start!
echo !I18N_launcher_options!
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean_disk.ps1" %*
pause
