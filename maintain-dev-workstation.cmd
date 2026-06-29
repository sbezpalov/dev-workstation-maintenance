@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ============================================================================
::  Dev Workstation Maintenance — Windows 11
::  Runtime: cmd.exe + winget (built-in on Win11)
::  Optional: node/npm, python/pip (post-update global packages)
:: ============================================================================

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%config\packages.list"
set "OPTIONAL_FILE=%SCRIPT_DIR%config\optional.ini"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "TIMESTAMP=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "LOG_FILE=%LOG_DIR%\maintain_%TIMESTAMP%.log"

if /i "%~1"=="-h" goto :usage
if /i "%~1"=="--help" goto :usage
if /i "%~1"=="/?" goto :usage

set "DRY_RUN=0"
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

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry-run" set "DRY_RUN=1"
if /i "%~1"=="--skip-npm" set "SKIP_NPM=1"
if /i "%~1"=="--skip-pip" set "SKIP_PIP=1"
if /i "%~1"=="--skip-winget" set "SKIP_WINGET=1"
if /i "%~1"=="--with-openclaw" set "INSTALL_OPENCLAW=1"
if /i "%~1"=="--with-openrouter" set "INSTALL_OPENROUTER=1"
if /i "%~1"=="--with-cursor" set "INSTALL_CURSOR=1"
if /i "%~1"=="--with-antigravity" set "INSTALL_ANTIGRAVITY=1"
if /i "%~1"=="--with-antigravity-cli" set "INSTALL_ANTIGRAVITY_CLI=1"
if /i "%~1"=="--with-claude" set "INSTALL_CLAUDE_DESKTOP=1"
if /i "%~1"=="--with-claude-code" set "INSTALL_CLAUDE_CODE=1"
if /i "%~1"=="--with-perplexity" set "INSTALL_PERPLEXITY=1"
if /i "%~1"=="--with-perplexity-comet" set "INSTALL_PERPLEXITY_COMET=1"
if /i "%~1"=="--with-ai-apps" call :enable_all_ai_apps
if /i "%~1"=="--openclaw-onboard" set "OPENCLAW_ONBOARD=1"
if /i "%~1"=="--openclaw-npm" set "OPENCLAW_INSTALL_METHOD=npm"
if /i "%~1"=="--openrouter-key" (
    shift
    set "OPENROUTER_API_KEY=%~1"
    set "INSTALL_OPENROUTER=1"
)
echo %~1| findstr /i /b /c:"--openrouter-key=" >nul 2>&1
if not errorlevel 1 (
    set "OPENROUTER_API_KEY=%~1"
    set "OPENROUTER_API_KEY=!OPENROUTER_API_KEY:--openrouter-key=!"
    set "INSTALL_OPENROUTER=1"
)
shift
goto :parse_args

:args_done
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

call :log "============================================================"
call :log " Dev Workstation Maintenance started"
call :log " Log: %LOG_FILE%"
if "%DRY_RUN%"=="1" call :log " MODE: dry-run (no changes)"
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
call :log " Maintenance finished"
call :log "============================================================"
echo.
echo Done. Log saved to: %LOG_FILE%
exit /b 0

:usage
echo.
echo Usage: maintain-dev-workstation.cmd [options]
echo.
echo Options:
echo   --dry-run                    Show planned actions without applying changes
echo   --skip-npm                   Skip npm global update and npm doctor
echo   --skip-pip                   Skip pip upgrade and pip check
echo   --skip-winget                Skip winget package maintenance
echo   --with-openclaw              Install OpenClaw (official install.ps1)
echo   --openclaw-onboard           Full install with interactive onboarding
echo   --openclaw-npm               Use npm instead of install.ps1
echo   --with-openrouter            Configure OpenRouter + install CLI
echo   --with-cursor                Install or upgrade Cursor IDE
echo   --with-antigravity           Install or upgrade Antigravity IDE
echo   --with-antigravity-cli       Install or upgrade Antigravity CLI
echo   --with-claude                Install or upgrade Claude desktop app
echo   --with-claude-code           Install or upgrade Claude Code CLI
echo   --with-perplexity            Install or upgrade Perplexity app
echo   --with-perplexity-comet      Install or upgrade Perplexity Comet browser
echo   --with-ai-apps               Install all optional AI apps above
echo   --openrouter-key KEY         OpenRouter API key (sk-or-v1-...)
echo   --help                       Show this help
echo.
echo Config: config\optional.ini and config\secrets.env (see secrets.env.example)
echo.
exit /b 0

:: ---------------------------------------------------------------------------
:check_prerequisites
call :log "[check] Verifying prerequisites..."

where winget >nul 2>&1
if errorlevel 1 (
    call :log "[ERROR] winget not found. Requires Windows 11 or App Installer."
    echo ERROR: winget is required. Install "App Installer" from Microsoft Store.
    exit /b 1
)

for /f "delims=" %%v in ('winget --version 2^>nul') do set "WINGET_VER=%%v"
call :log "[ok] winget version: !WINGET_VER!"

if not exist "%CONFIG_FILE%" (
    call :log "[ERROR] Config not found: %CONFIG_FILE%"
    exit /b 1
)
call :log "[ok] Config: %CONFIG_FILE%"
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
call :log "[path] Refreshing PATH from registry..."

set "SYSPATH="
set "USERPATH="

for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%b"

if defined SYSPATH set "PATH=!SYSPATH!"
if defined USERPATH set "PATH=!PATH!;!USERPATH!"
exit /b 0

:: ---------------------------------------------------------------------------
:run_winget_maintenance
call :log ""
call :log "[winget] Processing packages (sequential — avoids MSI lock)..."

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
call :log "[winget] %PKG_NAME% (%PKG_ID%) — action: %ACTION%"

if "%DRY_RUN%"=="1" (
    call :log "[dry-run] would run: winget %ACTION% --id %PKG_ID%"
    set /a PKG_SKIP+=1
    exit /b 0
)

if /i "%ACTION%"=="upgrade" (
    winget upgrade --id %PKG_ID% --accept-source-agreements --accept-package-agreements --disable-interactivity >> "%LOG_FILE%" 2>&1
) else if /i "%ACTION%"=="install" (
    winget install --id %PKG_ID% --accept-source-agreements --accept-package-agreements --disable-interactivity >> "%LOG_FILE%" 2>&1
) else (
    call :log "[warn] Unknown action '%ACTION%' for %PKG_ID%, skipped"
    set /a PKG_SKIP+=1
    exit /b 0
)

if errorlevel 1 (
    call :log "[warn] %PKG_NAME% — finished with warnings or no update available"
    set /a PKG_FAIL+=1
) else (
    call :log "[ok] %PKG_NAME% — success"
    set /a PKG_OK+=1
)

call :refresh_path
exit /b 0

:: ---------------------------------------------------------------------------
:run_npm_maintenance
call :log ""
call :log "[npm] Checking Node.js ecosystem..."

where node >nul 2>&1
if errorlevel 1 (
    call :log "[skip] node not in PATH"
    exit /b 0
)

for /f "delims=" %%v in ('node --version 2^>nul') do call :log "[info] node %%v"
for /f "delims=" %%v in ('npm --version 2^>nul') do call :log "[info] npm %%v"

if "%DRY_RUN%"=="1" (
    call :log "[dry-run] would run: npm install -g npm@latest"
    call :log "[dry-run] would run: npm update -g"
    call :log "[dry-run] would run: npm doctor"
    exit /b 0
)

call :log "[npm] Updating npm itself..."
call npm install -g npm@latest >> "%LOG_FILE%" 2>&1

call :log "[npm] Updating global packages..."
call npm update -g >> "%LOG_FILE%" 2>&1

call :log "[npm] Running npm doctor..."
call npm doctor >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    call :log "[warn] npm doctor reported issues — see log"
) else (
    call :log "[ok] npm doctor passed"
)
exit /b 0

:: ---------------------------------------------------------------------------
:run_pip_maintenance
call :log ""
call :log "[pip] Checking Python ecosystem (IDE assistants, MCP servers, CLI tools)..."

set "USE_PY_LAUNCHER=0"
where python >nul 2>&1
if errorlevel 1 (
    where py >nul 2>&1
    if errorlevel 1 (
        call :log "[skip] python not in PATH — restart terminal after winget install"
        exit /b 0
    )
    set "USE_PY_LAUNCHER=1"
)

if "!USE_PY_LAUNCHER!"=="0" (
    for /f "delims=" %%v in ('python --version 2^>nul') do call :log "[info] %%v"
    for /f "delims=" %%v in ('python -m pip --version 2^>nul') do call :log "[info] %%v"
) else (
    for /f "delims=" %%v in ('py -3 --version 2^>nul') do call :log "[info] %%v (via py launcher)"
    for /f "delims=" %%v in ('py -3 -m pip --version 2^>nul') do call :log "[info] %%v"
)

if "%DRY_RUN%"=="1" (
    call :log "[dry-run] would run: python -m pip install --upgrade pip"
    call :log "[dry-run] would run: upgrade outdated pip packages"
    call :log "[dry-run] would run: python -m pip check"
    exit /b 0
)

call :log "[pip] Upgrading pip..."
call :pip_cmd -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1

call :log "[pip] Upgrading outdated packages..."
if "!USE_PY_LAUNCHER!"=="0" (
    for /f "skip=2 tokens=1" %%p in ('python -m pip list -o 2^>nul') do (
        if not "%%p"=="" call :upgrade_pip_package "%%p"
    )
) else (
    for /f "skip=2 tokens=1" %%p in ('py -3 -m pip list -o 2^>nul') do (
        if not "%%p"=="" call :upgrade_pip_package "%%p"
    )
)

call :log "[pip] Running pip check..."
call :pip_cmd -m pip check >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    call :log "[warn] pip check reported issues — see log (may affect IDE Python extensions)"
) else (
    call :log "[ok] pip check passed"
)
exit /b 0

:pip_cmd
if "%USE_PY_LAUNCHER%"=="1" (
    py -3 %*
) else (
    python %*
)
exit /b %errorlevel%

:upgrade_pip_package
set "PKG=%~1"
if "%PKG%"=="" exit /b 0
call :log "[pip] upgrading %PKG%..."
call :pip_cmd -m pip install --upgrade "%PKG%" >> "%LOG_FILE%" 2>&1
exit /b 0

:: ---------------------------------------------------------------------------
:run_health_checks
call :log ""
call :log "[health] Tool versions after maintenance:"

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
    call :log "  openrouter-key: configured in this session (not shown)"
) else (
    reg query "HKCU\Environment" /v OPENROUTER_API_KEY >nul 2>&1
    if not errorlevel 1 (
        call :log "  openrouter-key: stored in user environment"
    )
)

where gh >nul 2>&1
if not errorlevel 1 (
    gh auth status >> "%LOG_FILE%" 2>&1
    if errorlevel 1 (
        call :log "[action] GitHub CLI not authenticated — run: gh auth login"
    ) else (
        call :log "[ok] GitHub CLI authenticated"
    )
)
exit /b 0

:report_tool
set "TOOL=%~1"
set "CMD=%~2"
where %TOOL% >nul 2>&1
if errorlevel 1 (
    call :log "  %TOOL%: not installed"
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
if not errorlevel 1 (
    for /f "delims=" %%o in ('python -m pip --version 2^>nul') do (
        call :log "  pip: %%o"
        exit /b 0
    )
)
where py >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%o in ('py -3 -m pip --version 2^>nul') do (
        call :log "  pip: %%o (via py launcher)"
        exit /b 0
    )
)
call :log "  pip: not installed"
exit /b 0

:: ---------------------------------------------------------------------------
:run_optional_apps_health
call "%SCRIPT_DIR%lib\optional-apps.cmd" health
exit /b 0

:: ---------------------------------------------------------------------------
:print_summary
call :log ""
call :log "[summary] winget ok=!PKG_OK! warn/fail=!PKG_FAIL! skipped=!PKG_SKIP!"
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
