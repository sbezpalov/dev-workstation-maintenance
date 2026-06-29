@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Optional AI desktop / IDE apps — winget install or upgrade
:: Requires: winget, env vars set by caller (SCRIPT_DIR, LOG_FILE, DRY_RUN, INSTALL_* flags)

set "OPTIONAL_APPS_FILE=%SCRIPT_DIR%config\optional-apps.list"

if /i "%~1"=="install" goto :install
if /i "%~1"=="health" goto :health
exit /b 1

:: ---------------------------------------------------------------------------
:install
if not exist "%OPTIONAL_APPS_FILE%" (
    call :log "[optional-apps] Config not found: %OPTIONAL_APPS_FILE%"
    exit /b 1
)

call :log "[optional-apps] AI desktop / IDE apps (winget)..."

set "APPS_OK=0"
set "APPS_FAIL=0"
set "APPS_SKIP=0"

for /f "usebackq tokens=1,2,3,4,5 delims=|" %%a in ("%OPTIONAL_APPS_FILE%") do (
    set "LINE=%%a"
    if not "!LINE:~0,1!"=="#" if not "%%a"=="" (
        call :process_app "%%a" "%%b" "%%c" "%%d" "%%e"
    )
)
if !APPS_OK! gtr 0 call :log "[summary] optional-apps ok=!APPS_OK! warn/fail=!APPS_FAIL!"
if !APPS_SKIP! gtr 0 call :log "[summary] optional-apps dry-run/skipped=!APPS_SKIP!"
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
call :log "[optional-apps] %APP_NAME% (%APP_ID%)"

if "!DRY_RUN!"=="1" (
    call :log "[dry-run] would install or upgrade via winget --id %APP_ID%"
    set /a APPS_SKIP+=1
    exit /b 0
)

set "APP_ACTION=install"
winget list --id %APP_ID% --disable-interactivity >nul 2>&1
if not errorlevel 1 set "APP_ACTION=upgrade"

call :log "[winget] %APP_ACTION% %APP_NAME%..."
if /i "!APP_ACTION!"=="upgrade" (
    winget upgrade --id %APP_ID% --accept-source-agreements --accept-package-agreements --disable-interactivity >> "!LOG_FILE!" 2>&1
) else (
    winget install --id %APP_ID% --accept-source-agreements --accept-package-agreements --disable-interactivity >> "!LOG_FILE!" 2>&1
)

if errorlevel 1 (
    call :log "[warn] %APP_NAME% — finished with warnings or no update available"
    set /a APPS_FAIL+=1
) else (
    call :log "[ok] %APP_NAME% — success"
    set /a APPS_OK+=1
)
exit /b 0

:: ---------------------------------------------------------------------------
:health
if not exist "%OPTIONAL_APPS_FILE%" exit /b 0

call :log ""
call :log "[health] Optional AI apps:"

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
    if errorlevel 1 (
        call :log "  %APP_NAME%: CLI not in PATH"
    ) else (
        for /f "delims=" %%o in ('%CLI_CMD% 2^>nul') do (
            call :log "  %APP_NAME%: %%o"
            goto :report_app_done
        )
    )
    goto :report_app_done
)

winget list --id %APP_ID% --disable-interactivity 2>nul | findstr /i /c:"%APP_ID%" >nul 2>&1
if errorlevel 1 (
    call :log "  %APP_NAME%: not installed"
) else (
    for /f "tokens=2" %%v in ('winget list --id %APP_ID% --disable-interactivity 2^>nul ^| findstr /i /c:"%APP_ID%"') do (
        call :log "  %APP_NAME%: installed (winget %%v)"
        goto :report_app_done
    )
    call :log "  %APP_NAME%: installed (winget)"
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
