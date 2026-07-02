@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ============================================================================
::  Dev Workstation Maintenance — Windows 11
::  Runtime: cmd.exe + winget (built-in on Win11)
::  Optional: node/npm, python/pip (post-update global packages)
:: ============================================================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%config\packages.list"
set "OPTIONAL_FILE=%SCRIPT_DIR%config\optional.ini"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "TIMESTAMP="
for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value 2^>nul') do set "dt=%%i"
if defined dt (
    set "TIMESTAMP=!dt:~0,8!_!dt:~8,6!"
) else (
    for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'" 2^>nul') do set "TIMESTAMP=%%i"
)
if not defined TIMESTAMP (
    set "TIMESTAMP=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "TIMESTAMP=!TIMESTAMP: =0!"
    set "TIMESTAMP=!TIMESTAMP:/=-!"
    set "TIMESTAMP=!TIMESTAMP::=-!"
)
set "LOG_FILE=%LOG_DIR%\maintain_%TIMESTAMP%.log"

set "SHOW_HELP=0"
set "SKIP_NPM=0"
set "SKIP_PIP=0"
set "SKIP_WINGET=0"
set "INSTALL_OPENCLAW=0"
set "INSTALL_OPENROUTER=0"
set "INSTALL_CURSOR=0"
set "INSTALL_ANTIGRAVITY=0"
set "INSTALL_ANTIGRAVITY_CLI=0"
set "INSTALL_CLAUDE_DESKTOP=0"
set "INSTALL_CLAUDE_CODE=0"
set "INSTALL_PERPLEXITY=0"
set "INSTALL_PERPLEXITY_COMET=0"
set "OPENCLAW_ONBOARD=0"
set "OPENCLAW_INSTALL_METHOD=installer"
set "OPENROUTER_CLI_PACKAGE=@openrouter/cli"
set "OPENROUTER_API_KEY="
set "PROJECT_LANGUAGE="

:parse_args
set "ARG=%~1"
if not defined ARG goto :args_done

if /i "!ARG!"=="-h" (
    set "SHOW_HELP=1"
    goto :continue_args
)
if /i "!ARG!"=="--help" (
    set "SHOW_HELP=1"
    goto :continue_args
)
if /i "!ARG!"=="/?" (
    set "SHOW_HELP=1"
    goto :continue_args
)
if /i "!ARG!"=="--dry-run" (
    set "DRY_RUN=1"
    goto :continue_args
)
if /i "!ARG!"=="--skip-npm" (
    set "SKIP_NPM=1"
    goto :continue_args
)
if /i "!ARG!"=="--skip-pip" (
    set "SKIP_PIP=1"
    goto :continue_args
)
if /i "!ARG!"=="--skip-winget" (
    set "SKIP_WINGET=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-openclaw" (
    set "INSTALL_OPENCLAW=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-openrouter" (
    set "INSTALL_OPENROUTER=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-cursor" (
    set "INSTALL_CURSOR=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-antigravity" (
    set "INSTALL_ANTIGRAVITY=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-antigravity-cli" (
    set "INSTALL_ANTIGRAVITY_CLI=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-claude" (
    set "INSTALL_CLAUDE_DESKTOP=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-claude-code" (
    set "INSTALL_CLAUDE_CODE=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-perplexity" (
    set "INSTALL_PERPLEXITY=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-perplexity-comet" (
    set "INSTALL_PERPLEXITY_COMET=1"
    goto :continue_args
)
if /i "!ARG!"=="--with-ai-apps" (
    call :enable_all_ai_apps
    goto :continue_args
)
if /i "!ARG!"=="--openclaw-onboard" (
    set "OPENCLAW_ONBOARD=1"
    goto :continue_args
)
if /i "!ARG!"=="--openclaw-npm" (
    set "OPENCLAW_INSTALL_METHOD=npm"
    goto :continue_args
)
if /i "!ARG!"=="--openrouter-key" (
    shift
    call set "OPENROUTER_API_KEY=%%~1"
    set "INSTALL_OPENROUTER=1"
    goto :continue_args
)
if /i "!ARG:~0,17!"=="--openrouter-key=" (
    set "OPENROUTER_API_KEY=!ARG:~17!"
    set "INSTALL_OPENROUTER=1"
    goto :continue_args
)
if /i "!ARG!"=="--language" (
    shift
    call set "PROJECT_LANGUAGE=%%~1"
    goto :continue_args
)
if /i "!ARG:~0,11!"=="--language=" (
    set "PROJECT_LANGUAGE=!ARG:~11!"
    goto :continue_args
)

:continue_args
shift
goto :parse_args

:args_done
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

call "%SCRIPT_DIR%lib\i18n.cmd" init

if "!SHOW_HELP!"=="1" goto :usage

call :log "============================================================"
call :log "!I18N_maintain_started!"
call :log "!I18N_maintain_log!"
if "%DRY_RUN%"=="1" call :log "!I18N_maintain_dry_run!"
call :log "============================================================"

call :check_prerequisites || exit /b 1
call :load_optional_config
call :refresh_path

if "%SKIP_WINGET%"=="0" call :run_winget_maintenance
if "%SKIP_PIP%"=="0" call :run_pip_maintenance
if "%SKIP_NPM%"=="0" call :run_npm_maintenance
set "NEED_OPTIONAL=0"
if "!INSTALL_OPENCLAW!"=="1" set "NEED_OPTIONAL=1"
if "!INSTALL_OPENROUTER!"=="1" set "NEED_OPTIONAL=1"
set "NEED_OPTIONAL_APPS=0"
if "!INSTALL_CURSOR!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_ANTIGRAVITY!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_ANTIGRAVITY_CLI!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_CLAUDE_DESKTOP!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_CLAUDE_CODE!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_PERPLEXITY!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!INSTALL_PERPLEXITY_COMET!"=="1" set "NEED_OPTIONAL_APPS=1"
if "!NEED_OPTIONAL!"=="1" call :run_optional_ai
if "!NEED_OPTIONAL_APPS!"=="1" call :run_optional_apps
call :run_health_checks
call :print_summary

call :log "============================================================"
call :log "!I18N_maintain_finished!"
call :log "============================================================"
echo.
echo !I18N_maintain_done!
exit /b 0

:usage
echo.
echo !I18N_maintain_usage_title!
echo.
echo !I18N_maintain_usage_opt_dry_run!
echo !I18N_maintain_usage_opt_skip_npm!
echo !I18N_maintain_usage_opt_skip_pip!
echo !I18N_maintain_usage_opt_skip_winget!
echo !I18N_maintain_usage_opt_openclaw!
echo !I18N_maintain_usage_opt_openclaw_onboard!
echo !I18N_maintain_usage_opt_openclaw_npm!
echo !I18N_maintain_usage_opt_openrouter!
echo !I18N_maintain_usage_opt_cursor!
echo !I18N_maintain_usage_opt_antigravity!
echo !I18N_maintain_usage_opt_antigravity_cli!
echo !I18N_maintain_usage_opt_claude!
echo !I18N_maintain_usage_opt_claude_code!
echo !I18N_maintain_usage_opt_perplexity!
echo !I18N_maintain_usage_opt_perplexity_comet!
echo !I18N_maintain_usage_opt_ai_apps!
echo !I18N_maintain_usage_opt_openrouter_key!
echo !I18N_maintain_usage_opt_language!
echo !I18N_maintain_usage_opt_help!
echo.
echo !I18N_maintain_usage_config_hint!
echo.
exit /b 0

:: ---------------------------------------------------------------------------
:check_prerequisites
call :log "!I18N_maintain_check_prereq!"

where winget >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_winget_missing!"
    echo !I18N_maintain_winget_missing_echo!
    exit /b 1
)

for /f "delims=" %%v in ('winget --version 2^>nul') do set "WINGET_VER=%%v"
call :log "[ok] winget version: !WINGET_VER!"

if not exist "%CONFIG_FILE%" (
    call :log "!I18N_maintain_config_missing!"
    exit /b 1
)
call :log "!I18N_maintain_config_ok!"
exit /b 0

:: ---------------------------------------------------------------------------
:load_optional_config
if not exist "%OPTIONAL_FILE%" exit /b 0

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%OPTIONAL_FILE%") do (
    set "KEY=%%a"
    set "VAL=%%b"
    if defined KEY (
        if defined VAL set "VAL=!VAL: =!"
        if /i "!KEY!"=="INSTALL_OPENCLAW" if "!INSTALL_OPENCLAW!"=="0" set "INSTALL_OPENCLAW=!VAL!"
        if /i "!KEY!"=="INSTALL_OPENROUTER" if "!INSTALL_OPENROUTER!"=="0" set "INSTALL_OPENROUTER=!VAL!"
        if /i "!KEY!"=="INSTALL_CURSOR" if "!INSTALL_CURSOR!"=="0" set "INSTALL_CURSOR=!VAL!"
        if /i "!KEY!"=="INSTALL_ANTIGRAVITY" if "!INSTALL_ANTIGRAVITY!"=="0" set "INSTALL_ANTIGRAVITY=!VAL!"
        if /i "!KEY!"=="INSTALL_ANTIGRAVITY_CLI" if "!INSTALL_ANTIGRAVITY_CLI!"=="0" set "INSTALL_ANTIGRAVITY_CLI=!VAL!"
        if /i "!KEY!"=="INSTALL_CLAUDE_DESKTOP" if "!INSTALL_CLAUDE_DESKTOP!"=="0" set "INSTALL_CLAUDE_DESKTOP=!VAL!"
        if /i "!KEY!"=="INSTALL_CLAUDE_CODE" if "!INSTALL_CLAUDE_CODE!"=="0" set "INSTALL_CLAUDE_CODE=!VAL!"
        if /i "!KEY!"=="INSTALL_PERPLEXITY" if "!INSTALL_PERPLEXITY!"=="0" set "INSTALL_PERPLEXITY=!VAL!"
        if /i "!KEY!"=="INSTALL_PERPLEXITY_COMET" if "!INSTALL_PERPLEXITY_COMET!"=="0" set "INSTALL_PERPLEXITY_COMET=!VAL!"
        if /i "!KEY!"=="OPENCLAW_ONBOARD" if "!OPENCLAW_ONBOARD!"=="0" set "OPENCLAW_ONBOARD=!VAL!"
        if /i "!KEY!"=="OPENCLAW_INSTALL_METHOD" set "OPENCLAW_INSTALL_METHOD=!VAL!"
        if /i "!KEY!"=="OPENROUTER_CLI_PACKAGE" set "OPENROUTER_CLI_PACKAGE=!VAL!"
    )
)
exit /b 0

:: ---------------------------------------------------------------------------
:run_optional_ai
call "%SCRIPT_DIR%lib\optional-ai.cmd" install
exit /b 0

:: ---------------------------------------------------------------------------
:run_optional_apps
call "%SCRIPT_DIR%lib\optional-apps.cmd" install
call :refresh_path
exit /b 0

:: ---------------------------------------------------------------------------
:enable_all_ai_apps
set "INSTALL_CURSOR=1"
set "INSTALL_ANTIGRAVITY=1"
set "INSTALL_ANTIGRAVITY_CLI=1"
set "INSTALL_CLAUDE_DESKTOP=1"
set "INSTALL_CLAUDE_CODE=1"
set "INSTALL_PERPLEXITY=1"
set "INSTALL_PERPLEXITY_COMET=1"
exit /b 0

:: ---------------------------------------------------------------------------
:refresh_path
call :log "!I18N_maintain_path_refresh!"

set "SYSPATH="
set "USERPATH="

for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%b"

if defined SYSPATH set "PATH=!SYSPATH!"
if defined USERPATH set "PATH=!PATH!;!USERPATH!"
call set "PATH=!PATH!"
exit /b 0

:: ---------------------------------------------------------------------------
:run_winget_maintenance
call :log ""
call :log "!I18N_maintain_winget_processing!"

set "PKG_OK=0"
set "PKG_FAIL=0"
set "PKG_SKIP=0"

for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%CONFIG_FILE%") do (
    set "LINE=%%a"
    if not "!LINE:~0,1!"=="#" if not "%%a"=="" (
        call :process_package "%%a" "%%b" "%%c"
    )
)
exit /b 0

:process_package
set "ACTION=%~1"
set "PKG_ID=%~2"
set "PKG_NAME=%~3"

if "%ACTION%"=="" exit /b 0
if "%PKG_ID%"=="" exit /b 0

call :log ""
call :log "!I18N_maintain_winget_package!"

if "%DRY_RUN%"=="1" (
    call :log "!I18N_maintain_winget_dry_run!"
    set /a PKG_SKIP+=1
    exit /b 0
)

if /i "%ACTION%"=="upgrade" (
    winget upgrade --id "%PKG_ID%" --accept-source-agreements --accept-package-agreements --disable-interactivity >> "%LOG_FILE%" 2>&1
) else if /i "%ACTION%"=="install" (
    winget install --id "%PKG_ID%" --accept-source-agreements --accept-package-agreements --disable-interactivity >> "%LOG_FILE%" 2>&1
) else (
    call :log "!I18N_maintain_winget_unknown!"
    set /a PKG_SKIP+=1
    exit /b 0
)

if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_winget_warn!"
    set /a PKG_FAIL+=1
) else (
    call :log "!I18N_maintain_winget_ok!"
    set /a PKG_OK+=1
)

call :refresh_path
exit /b 0

:: ---------------------------------------------------------------------------
:run_npm_maintenance
call :log ""
call :log "!I18N_maintain_npm_check!"

where node >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_npm_skip!"
    exit /b 0
)

for /f "delims=" %%v in ('node --version 2^>nul') do call :log "[info] node %%v"
for /f "delims=" %%v in ('npm --version 2^>nul') do call :log "[info] npm %%v"

if "%DRY_RUN%"=="1" (
    call :log "!I18N_maintain_npm_dry1!"
    call :log "!I18N_maintain_npm_dry2!"
    call :log "!I18N_maintain_npm_dry3!"
    exit /b 0
)

call :log "!I18N_maintain_npm_update_self!"
call npm install -g npm@latest >> "%LOG_FILE%" 2>&1

call :log "!I18N_maintain_npm_update_global!"
call npm update -g >> "%LOG_FILE%" 2>&1

call :log "!I18N_maintain_npm_doctor!"
call npm doctor >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_npm_doctor_warn!"
) else (
    call :log "!I18N_maintain_npm_doctor_ok!"
)
exit /b 0

:: ---------------------------------------------------------------------------
:run_pip_maintenance
call :log ""
call :log "!I18N_maintain_pip_check!"

set "USE_PY_LAUNCHER=0"
where python >nul 2>&1
if !ERRORLEVEL! neq 0 (
    where py >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        call :log "!I18N_maintain_pip_skip!"
        exit /b 0
    )
    set "USE_PY_LAUNCHER=1"
)

if "!USE_PY_LAUNCHER!"=="0" (
    for /f "delims=" %%v in ('python --version 2^>nul') do call :log "[info] %%v"
    for /f "delims=" %%v in ('python -m pip --version 2^>nul') do call :log "[info] %%v"
) else (
    for /f "delims=" %%v in ('py -3 --version 2^>nul') do call :log "[info] %%v !I18N_maintain_pip_via_py!"
    for /f "delims=" %%v in ('py -3 -m pip --version 2^>nul') do call :log "[info] %%v"
)

if "%DRY_RUN%"=="1" (
    call :log "!I18N_maintain_pip_dry1!"
    call :log "!I18N_maintain_pip_dry2!"
    call :log "!I18N_maintain_pip_dry3!"
    exit /b 0
)

call :log "!I18N_maintain_pip_upgrade!"
call :pip_cmd -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1

call :log "!I18N_maintain_pip_outdated!"
if "!USE_PY_LAUNCHER!"=="0" (
    for /f "skip=2 tokens=1" %%p in ('python -m pip list -o 2^>nul') do (
        if not "%%p"=="" call :upgrade_pip_package "%%p"
    )
) else (
    for /f "skip=2 tokens=1" %%p in ('py -3 -m pip list -o 2^>nul') do (
        if not "%%p"=="" call :upgrade_pip_package "%%p"
    )
)

call :log "!I18N_maintain_pip_check_run!"
call :pip_cmd -m pip check >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_pip_check_warn!"
) else (
    call :log "!I18N_maintain_pip_check_ok!"
)
exit /b 0

:pip_cmd
if "%USE_PY_LAUNCHER%"=="1" (
    py -3 %*
) else (
    python %*
)
exit /b !ERRORLEVEL!

:upgrade_pip_package
set "PKG=%~1"
if "%PKG%"=="" exit /b 0
call :log "!I18N_maintain_pip_upgrading!"
call :pip_cmd -m pip install --upgrade "%PKG%" >> "%LOG_FILE%" 2>&1
exit /b 0

:: ---------------------------------------------------------------------------
:run_health_checks
call :log ""
call :log "!I18N_maintain_health_title!"

call :report_tool "python" "python --version"
call :report_tool "py" "py --version"
call :report_pip_version
call :report_tool "node" "node --version"
call :report_tool "npm" "npm --version"
call :report_tool "git" "git --version"
call :report_tool "go" "go version"
call :report_tool "php" "php -v"
call :report_tool "pwsh" "pwsh -Version"
call :report_tool "gh" "gh --version"
call :report_tool "code" "code --version"
call :report_tool "openclaw" "openclaw --version"
call :report_tool "openrouter" "openrouter --version"
call :run_optional_apps_health

if defined OPENROUTER_API_KEY (
    call :log "!I18N_maintain_openrouter_key_session!"
) else (
    reg query "HKCU\Environment" /v OPENROUTER_API_KEY >nul 2>&1
    if !ERRORLEVEL! == 0 (
        call :log "!I18N_maintain_openrouter_key_stored!"
    )
)

where gh >nul 2>&1
if !ERRORLEVEL! == 0 (
    gh auth status >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        call :log "!I18N_maintain_gh_auth_action!"
    ) else (
        call :log "!I18N_maintain_gh_auth_ok!"
    )
)
exit /b 0

:report_tool
set "TOOL=%~1"
set "CMD=%~2"
where %TOOL% >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_maintain_tool_not_installed!"
) else (
    for /f "delims=" %%o in ('%CMD% 2^>nul') do (
        call :log "  %TOOL%: %%o"
        goto :report_done
    )
)
:report_done
exit /b 0

:report_pip_version
where python >nul 2>&1
if !ERRORLEVEL! == 0 (
    for /f "delims=" %%o in ('python -m pip --version 2^>nul') do (
        call :log "  pip: %%o"
        exit /b 0
    )
)
where py >nul 2>&1
if !ERRORLEVEL! == 0 (
    for /f "delims=" %%o in ('py -3 -m pip --version 2^>nul') do (
        call :log "  pip: %%o !I18N_maintain_pip_via_py!"
        exit /b 0
    )
)
call :log "!I18N_maintain_pip_not_installed!"
exit /b 0

:: ---------------------------------------------------------------------------
:run_optional_apps_health
call "%SCRIPT_DIR%lib\optional-apps.cmd" health
exit /b 0

:: ---------------------------------------------------------------------------
:print_summary
call :log ""
call :log "!I18N_maintain_summary_winget!"
exit /b 0

:: ---------------------------------------------------------------------------
:log
set "MSG=%~1"
if not defined MSG (
    echo.
    echo.>> "%LOG_FILE%"
) else (
    echo !MSG!
    echo !MSG!>> "%LOG_FILE%"
)
exit /b 0
