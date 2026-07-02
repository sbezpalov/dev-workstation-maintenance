@echo off
chcp 65001 > nul
echo Запуск очистки диска C (все пользователи, при необходимости - UAC)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean_disk.ps1"
pause
