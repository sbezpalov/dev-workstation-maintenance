@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "OPTIONAL_APPS_FILE=%SCRIPT_DIR%config\optional-apps.list"

if /i "%~1"=="install" goto :install
if /i "%~1"=="health" goto :health
exit /b 1

:: ---------------------------------------------------------------------------
:install
if not exist "%OPTIONAL_APPS_FILE%" (
    call :log "!I18N_optional_apps_config_missing!"
    exit /b 1
)

call :log "!I18N_optional_apps_header!"

set "APPS_OK=0"
set "APPS_FAIL=0"
set "APPS_SKIP=0"

for /f "usebackq tokens=1,2,3,4,5 delims=|" %%a in ("%OPTIONAL_APPS_FILE%") do (
    set "LINE=%%a"
    if not "!LINE:~0,1!"=="#" if not "%%a"=="" (
        call :process_app "%%a" "%%b" "%%c" "%%d" "%%e"
    )
)
if !APPS_OK! gtr 0 call :log "!I18N_optional_apps_summary_ok!"
if !APPS_SKIP! gtr 0 call :log "!I18N_optional_apps_summary_skip!"
exit /b 0

:process_app
set "APP_FLAG=%~1"
set "APP_ID=%~2"
set "APP_NAME=%~3"

if "%APP_FLAG%"=="" exit /b 0
if "%APP_ID%"=="" exit /b 0

call set "APP_ENABLED=%%%APP_FLAG%%%"
if not "!APP_ENABLED!"=="1" exit /b 0

call :log ""
call :log "!I18N_optional_apps_app_line!"

if "!DRY_RUN!"=="1" (
    call :log "!I18N_optional_apps_dry_run!"
    set /a APPS_SKIP+=1
    exit /b 0
)

set "APP_ACTION=install"
winget list --id "%APP_ID%" --disable-interactivity >nul 2>&1
if !ERRORLEVEL! == 0 set "APP_ACTION=upgrade"

call :log "!I18N_optional_apps_winget_action!"
if /i "!APP_ACTION!"=="upgrade" (
    winget upgrade --id "%APP_ID%" --accept-source-agreements --accept-package-agreements --disable-interactivity >> "!LOG_FILE!" 2>&1
) else (
    winget install --id "%APP_ID%" --accept-source-agreements --accept-package-agreements --disable-interactivity >> "!LOG_FILE!" 2>&1
)

if !ERRORLEVEL! neq 0 (
    call :log "!I18N_optional_apps_warn!"
    set /a APPS_FAIL+=1
) else (
    call :log "!I18N_optional_apps_ok!"
    set /a APPS_OK+=1
)
exit /b 0

:: ---------------------------------------------------------------------------
:health
if not exist "%OPTIONAL_APPS_FILE%" exit /b 0

call :log ""
call :log "!I18N_optional_apps_health_title!"

for /f "usebackq tokens=1,2,3,4,5 delims=|" %%a in ("%OPTIONAL_APPS_FILE%") do (
    set "LINE=%%a"
    if not "!LINE:~0,1!"=="#" if not "%%a"=="" (
        call :report_app "%%a" "%%b" "%%c" "%%d" "%%e"
    )
)
exit /b 0

:report_app
set "APP_FLAG=%~1"
set "APP_ID=%~2"
set "APP_NAME=%~3"
set "CLI_TOOL=%~4"
set "CLI_CMD=%~5"

if defined CLI_TOOL if not "%CLI_TOOL%"=="" (
    where %CLI_TOOL% >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        call :log "!I18N_optional_apps_cli_not_in_path!"
    ) else (
        for /f "delims=" %%o in ('%CLI_CMD% 2^>nul') do (
            call :log "  %APP_NAME%: %%o"
            goto :report_app_done
        )
    )
    goto :report_app_done
)

winget list --id "%APP_ID%" --disable-interactivity 2>nul | findstr /i /c:"%APP_ID%" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_optional_apps_not_installed!"
) else (
    set "APP_VER="
    set "FOUND=0"
    for /f "usebackq delims=" %%i in (`winget list --id "%APP_ID%" --disable-interactivity 2^>nul ^| findstr /i /c:"%APP_ID%"`) do (
        set "FOUND=1"
        set "LINE=%%i"
        set "VERSION_PART=!LINE:*%APP_ID%=!"
        for /f "tokens=1" %%v in ("!VERSION_PART!") do set "APP_VER=%%v"
    )
    if "!FOUND!"=="1" (
        if defined APP_VER (
            call :log "!I18N_optional_apps_installed_version!"
        ) else (
            call :log "!I18N_optional_apps_installed!"
        )
    ) else (
        call :log "!I18N_optional_apps_not_installed!"
    )
)
:report_app_done
exit /b 0

:: ---------------------------------------------------------------------------
:log
set "MSG=%~1"
if not defined MSG (
    echo.
    if defined LOG_FILE echo.>> "!LOG_FILE!"
) else (
    echo !MSG!
    if defined LOG_FILE echo !MSG!>> "!LOG_FILE!"
)
exit /b 0
