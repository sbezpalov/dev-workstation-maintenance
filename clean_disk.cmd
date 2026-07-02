@echo off
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . '%~dp0lib\cleanup-i18n.ps1'; $p='%~dp0config\cleanup.ini'; Initialize-CleanupLanguage -Override (Get-CleanupLanguagePreference -IniFile $p); Write-Host (Get-CleanupMsg 'launcher.start'); Write-Host (Get-CleanupMsg 'launcher.options') }"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean_disk.ps1" %*
pause
