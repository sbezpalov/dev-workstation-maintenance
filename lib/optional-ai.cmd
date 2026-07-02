@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Optional AI services module — called from maintain-dev-workstation.cmd

if /i not "%~1"=="install" exit /b 1

call :log "!I18N_openclaw_optional_block!"

if "!INSTALL_OPENCLAW!"=="1" call :install_openclaw
if "!INSTALL_OPENROUTER!"=="1" call :install_openrouter

exit /b 0

:: ---------------------------------------------------------------------------
:install_openclaw
call :log ""
if /i not "!OPENCLAW_INSTALL_METHOD!"=="npm" (
    call :install_openclaw_official
) else (
    call :install_openclaw_npm
)
exit /b 0

:install_openclaw_official
call :log "!I18N_openclaw_install_official!"

where powershell >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openclaw_ps_missing!"
    call :install_openclaw_npm
    exit /b 0
)

if "!DRY_RUN!"=="1" (
    if "!OPENCLAW_ONBOARD!"=="1" (
        call :log "!I18N_openclaw_dry_full!"
    ) else (
        call :log "!I18N_openclaw_dry_quick!"
    )
    exit /b 0
)

if "!OPENCLAW_ONBOARD!"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://openclaw.ai/install.ps1 | iex" >> "!LOG_FILE!" 2>&1
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Invoke-RestMethod -UseBasicParsing 'https://openclaw.ai/install.ps1'))) -NoOnboard" >> "!LOG_FILE!" 2>&1
)

if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openclaw_warn_fallback!"
    call :install_openclaw_npm
    exit /b 0
)

call :log "!I18N_openclaw_ok_official!"
call :verify_openclaw
exit /b 0

:install_openclaw_npm
call :log "!I18N_openclaw_install_npm!"

where node >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openclaw_skip_no_node!"
    exit /b 0
)

if "!DRY_RUN!"=="1" (
    call :log "!I18N_openclaw_dry_npm!"
    if "!OPENCLAW_ONBOARD!"=="1" call :log "!I18N_openclaw_dry_onboard!"
    exit /b 0
)

call npm.cmd install -g openclaw@latest >> "!LOG_FILE!" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openclaw_warn_npm_fail!"
    exit /b 0
)

call :log "!I18N_openclaw_ok_npm!"
call :verify_openclaw

if "!OPENCLAW_ONBOARD!"=="1" (
    call :log "!I18N_openclaw_onboard_start!"
    openclaw onboard --install-daemon
)
exit /b 0

:verify_openclaw
where openclaw >nul 2>&1
if !ERRORLEVEL! == 0 (
    for /f "delims=" %%v in ('openclaw --version 2^>nul') do call :log "[info] openclaw %%v"
    call openclaw doctor --non-interactive >> "!LOG_FILE!" 2>&1
) else (
    call :log "!I18N_openclaw_not_in_path!"
)
exit /b 0

:: ---------------------------------------------------------------------------
:install_openrouter
call :log ""
call :log "!I18N_openrouter_configuring!"

if not defined OPENROUTER_API_KEY (
    call :load_secret OPENROUTER_API_KEY
)

if not defined OPENROUTER_API_KEY (
    call :log "!I18N_openrouter_skip_no_key!"
    exit /b 0
)

if "!DRY_RUN!"=="1" (
    call :log "!I18N_openrouter_dry_store_env!"
    call :log "!I18N_openrouter_dry_install_cli!"
    exit /b 0
)

set "TMP_VAL=!OPENROUTER_API_KEY!"
call :set_user_env "OPENROUTER_API_KEY" "TMP_VAL"
set "TMP_VAL=https://openrouter.ai/api"
call :set_user_env "ANTHROPIC_BASE_URL" "TMP_VAL"
set "TMP_VAL=!OPENROUTER_API_KEY!"
call :set_user_env "ANTHROPIC_AUTH_TOKEN" "TMP_VAL"
set "TMP_VAL="
call :set_user_env "ANTHROPIC_API_KEY" "TMP_VAL"
call :log "!I18N_openrouter_ok_env_saved!"

set "OPENROUTER_API_KEY=!OPENROUTER_API_KEY!"
set "ANTHROPIC_BASE_URL=https://openrouter.ai/api"
set "ANTHROPIC_AUTH_TOKEN=!OPENROUTER_API_KEY!"
set "ANTHROPIC_API_KEY="

where node >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openrouter_warn_no_node!"
    exit /b 0
)

if not defined OPENROUTER_CLI_PACKAGE set "OPENROUTER_CLI_PACKAGE=@openrouter/cli"
call :log "!I18N_openrouter_installing_cli!"
call npm.cmd install -g !OPENROUTER_CLI_PACKAGE! >> "!LOG_FILE!" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log "!I18N_openrouter_warn_cli_failed!"
) else (
    call :log "!I18N_openrouter_ok_cli_installed!"
    where openrouter >nul 2>&1
    if !ERRORLEVEL! == 0 (
        for /f "delims=" %%v in ('openrouter --version 2^>nul') do call :log "[info] openrouter %%v"
    )
)
exit /b 0

:: ---------------------------------------------------------------------------
:load_secret
set "SECRET_NAME=%~1"
set "SECRETS_FILE=%SCRIPT_DIR%config\secrets.env"
if not exist "!SECRETS_FILE!" exit /b 0

for /f "usebackq eol=# tokens=1,* delims==" %%a in ("!SECRETS_FILE!") do (
    if /i "%%a"=="!SECRET_NAME!" (
        set "VAL=%%b"
        if defined VAL set "VAL=!VAL:"=!"
        set "!SECRET_NAME!=!VAL!"
    )
)
exit /b 0

:: ---------------------------------------------------------------------------
:set_user_env
set "ENV_NAME=%~1"
set "ENV_VAR_NAME=%~2"
set "ENV_VALUE="
if defined ENV_VAR_NAME set "ENV_VALUE=!%ENV_VAR_NAME%!"
reg add "HKCU\Environment" /v "!ENV_NAME!" /t REG_SZ /d "!ENV_VALUE!" /f >> "!LOG_FILE!" 2>&1
exit /b !ERRORLEVEL!

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
