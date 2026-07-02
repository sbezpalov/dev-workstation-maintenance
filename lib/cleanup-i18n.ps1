# Cleanup UI strings - ru | en (auto from system UI language)

$script:CleanupLang = 'en'

function Initialize-CleanupLanguage {
    param([string]$Override)

    $normalized = $null
    if ($Override) {
        switch -Regex ($Override.Trim()) {
            '^(ru|ru-RU|ru-ru)$' { $normalized = 'ru'; break }
            '^(en|en-US|en-us)$' { $normalized = 'en'; break }
            '^auto$' { $normalized = $null; break }
            default { $normalized = $null }
        }
    }

    if ($normalized) {
        $script:CleanupLang = $normalized
        return
    }

    $culture = [System.Globalization.CultureInfo]::InstalledUICulture
    if ($culture.TwoLetterISOLanguageName -eq 'ru') {
        $script:CleanupLang = 'ru'
    } else {
        $script:CleanupLang = 'en'
    }
}

function Get-CleanupLanguagePreference {
    param([string]$IniFile)

    if (-not (Test-Path -LiteralPath $IniFile)) {
        return 'auto'
    }

    foreach ($line in Get-Content -LiteralPath $IniFile -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        $parts = $trimmed -split '=', 2
        if ($parts.Count -lt 2) { continue }
        if ($parts[0].Trim() -eq 'LANGUAGE') {
            return $parts[1].Trim()
        }
    }

    return 'auto'
}

$CleanupMessages = @{
    ru = @{
        'launcher.start'              = 'Запуск очистки диска C (все пользователи, уровень из config\cleanup.ini)...'
        'launcher.options'            = 'Опции: -DryRun  -Tier safe|developer|aggressive  -Language ru|en'
        'uac.need_admin'              = 'Для очистки всех профилей нужны права администратора.'
        'uac.prompt'                  = 'Запрос подтверждения UAC...'
        'uac.cancelled'               = 'Запуск от имени администратора отменён.'
        'start.header'                = 'Очистка диска {0} (администратор)'
        'start.dry_run'               = 'РЕЖИМ: dry-run (без удаления)'
        'start.tier'                  = 'Уровень: {0}'
        'summary.done'                = 'Очистка завершена'
        'summary.tier'                = 'Уровень: {0}{1}'
        'summary.dry_run_suffix'      = ' (dry-run)'
        'summary.by_category'         = 'По категориям (измеренные папки):'
        'summary.category_line'       = '  {0}: {1} МБ'
        'summary.tracked'             = 'Учтено очисткой: {0} МБ'
        'summary.disk_delta'          = 'Прирост свободного места: {0} МБ ({1} ГБ)'
        'summary.free_on'             = 'Доступно на {0}: {1} ГБ'
        'summary.log'                 = 'Журнал: {0}'
        'skip.not_found'              = '  [пропуск] {0} - не найдено'
        'dry_run.folder'              = '  [dry-run] {0} - {1} ({2} МБ)'
        'clean.folder'                = '  [очистка] {0} - {1} ({2} МБ)'
        'ok.freed'                    = '  [ok] {0} - освобождено {1} МБ'
        'error.list_not_found'        = 'Файл списка очистки не найден: {0}'
        'user.profile_cleanup'        = '[user] Очистка профилей'
        'user.no_profiles'            = '[warn] Профили пользователей не найдены'
        'user.profiles_count'         = 'Профилей: {0} | уровень: {1}'
        'user.loose_clean'            = '  [очистка] *.tmp / *.dmp / *.crash в корне профиля'
        'user.loose_dry'              = '  [dry-run] удаление временных файлов в корне профиля'
        'system.path_cleanup'         = '[system] Системные папки'
        'system.cleanmgr_disabled'    = '[пропуск] cleanmgr отключён в config\cleanup.ini'
        'system.cleanmgr_not_found'   = '[пропуск] cleanmgr.exe не найден'
        'system.cleanmgr_start'       = '[cleanmgr] Очистка диска Windows (sagerun:{0}, диск {1})'
        'system.cleanmgr_dry'         = '[dry-run] будет запущено: cleanmgr /sagerun:{0} /d {1}'
        'system.cleanmgr_ok'          = '[ok] cleanmgr - освобождено ~{0} МБ'
        'system.cleanmgr_no_change'   = '[info] cleanmgr завершён (нет изменений или профиль не настроен)'
        'system.cleanmgr_setup'       = '[info] Один раз выполните: cleanmgr /sageset:65535 - выберите все категории'
        'system.recycle_disabled'     = '[пропуск] очистка корзины отключена'
        'system.recycle_header'       = '[system] Корзина'
        'system.recycle_dry'          = '[dry-run] будет выполнено: Clear-RecycleBin -Force'
        'system.recycle_ok'           = '[ok] Корзина очищена'
        'system.recycle_warn'         = '[warn] Корзина: {0}'
        'category.user'               = 'пользователь'
        'category.system'             = 'система'
        'target.user_temp'            = 'Временные файлы пользователя'
        'target.d3d_shader_cache'     = 'Кэш шейдеров DirectX (Windows)'
        'target.nvidia_dxcache'       = 'NVIDIA DXCache'
        'target.nvidia_glcache'       = 'NVIDIA GLCache'
        'target.amd_dx9cache'         = 'AMD DX9 Shader Cache'
        'target.amd_dxcache'          = 'AMD DX Shader Cache'
        'target.amd_dxccache'         = 'AMD DXC Shader Cache'
        'target.amd_vkcache'          = 'AMD Vulkan Cache'
        'target.amd_glcache'          = 'AMD OpenGL Cache'
        'target.amd_oglpcache'        = 'AMD OpenGL Cache (новый)'
        'target.amd_dx9cache_ll'      = 'AMD DX9 Cache (LocalLow)'
        'target.amd_dxcache_ll'       = 'AMD DX Cache (LocalLow)'
        'target.amd_dxccache_ll'      = 'AMD DXC Cache (LocalLow)'
        'target.amd_vkcache_ll'       = 'AMD Vulkan Cache (LocalLow)'
        'target.amd_glcache_ll'       = 'AMD OpenGL Cache (LocalLow)'
        'target.amd_oglpcache_ll'     = 'AMD OpenGL Cache (LocalLow)'
        'target.windows_temp'         = 'Windows Temp'
        'target.pip_cache'            = 'Кэш pip'
        'target.npm_cache'            = 'Кэш npm'
        'target.go_build'             = 'Кэш сборки Go'
        'target.crash_dumps'          = 'Crash dumps'
        'target.inet_cache'           = 'Кэш Internet'
        'target.web_cache'            = 'Web cache'
        'target.intel_shader_cache'   = 'Кэш шейдеров Intel'
        'target.cursor_cache'         = 'Кэш Cursor IDE'
        'target.cursor_cached_data'   = 'Cursor CachedData'
        'target.cursor_code_cache'    = 'Cursor Code Cache'
        'target.vscode_cache'         = 'Кэш VS Code'
        'target.vscode_cached_data'   = 'VS Code CachedData'
        'target.vscode_code_cache'    = 'VS Code Code Cache'
        'target.winget_installers'    = 'Установщики WinGet'
        'target.winget_cache'         = 'Кэш WinGet'
        'target.nuget_packages'       = 'Кэш пакетов NuGet'
        'target.gradle_caches'        = 'Кэш Gradle'
        'target.cargo_registry'       = 'Кэш Cargo registry'
        'target.cargo_git'            = 'Cargo git checkouts'
        'target.pnpm_store'           = 'Хранилище pnpm'
        'target.yarn_cache'           = 'Кэш Yarn'
        'target.windows_disk_cleanup' = 'Очистка диска Windows'
    }
    en = @{
        'launcher.start'              = 'Starting drive C cleanup (all users, tier from config\cleanup.ini)...'
        'launcher.options'            = 'Options: -DryRun  -Tier safe|developer|aggressive  -Language ru|en'
        'uac.need_admin'              = 'Administrator rights are required to clean all user profiles.'
        'uac.prompt'                  = 'Requesting UAC elevation...'
        'uac.cancelled'               = 'Elevation was cancelled.'
        'start.header'                = 'Disk cleanup {0} (administrator)'
        'start.dry_run'               = 'MODE: dry-run (no deletions)'
        'start.tier'                  = 'Tier: {0}'
        'summary.done'                = 'Cleanup finished'
        'summary.tier'                = 'Tier: {0}{1}'
        'summary.dry_run_suffix'      = ' (dry-run)'
        'summary.by_category'         = 'By category (measured folders):'
        'summary.category_line'       = '  {0}: {1} MB'
        'summary.tracked'             = 'Tracked cleanup: {0} MB'
        'summary.disk_delta'          = 'Disk free delta: {0} MB ({1} GB)'
        'summary.free_on'             = 'Free on {0}: {1} GB'
        'summary.log'                 = 'Log: {0}'
        'skip.not_found'              = '  [skip] {0} - not found'
        'dry_run.folder'              = '  [dry-run] {0} - {1} ({2} MB)'
        'clean.folder'                = '  [clean] {0} - {1} ({2} MB)'
        'ok.freed'                    = '  [ok] {0} - freed {1} MB'
        'error.list_not_found'        = 'Cleanup list not found: {0}'
        'user.profile_cleanup'        = '[user] Profile cleanup'
        'user.no_profiles'            = '[warn] No user profiles found'
        'user.profiles_count'         = 'Profiles: {0} | tier: {1}'
        'user.loose_clean'            = '  [clean] Loose *.tmp / *.dmp / *.crash in profile root'
        'user.loose_dry'              = '  [dry-run] would remove loose temp files in profile root'
        'system.path_cleanup'         = '[system] System folders'
        'system.cleanmgr_disabled'    = '[skip] cleanmgr disabled in config\cleanup.ini'
        'system.cleanmgr_not_found'   = '[skip] cleanmgr.exe not found'
        'system.cleanmgr_start'       = '[cleanmgr] Windows Disk Cleanup (sagerun:{0}, drive {1})'
        'system.cleanmgr_dry'         = '[dry-run] would run: cleanmgr /sagerun:{0} /d {1}'
        'system.cleanmgr_ok'          = '[ok] cleanmgr - freed ~{0} MB'
        'system.cleanmgr_no_change'   = '[info] cleanmgr finished (no measurable change or profile not configured)'
        'system.cleanmgr_setup'       = '[info] Run once: cleanmgr /sageset:65535 - select all categories'
        'system.recycle_disabled'     = '[skip] Recycle Bin cleanup disabled'
        'system.recycle_header'       = '[system] Recycle Bin'
        'system.recycle_dry'          = '[dry-run] would run: Clear-RecycleBin -Force'
        'system.recycle_ok'           = '[ok] Recycle Bin cleared'
        'system.recycle_warn'         = '[warn] Recycle Bin: {0}'
        'category.user'               = 'user'
        'category.system'             = 'system'
        'target.user_temp'            = 'User Temp'
        'target.d3d_shader_cache'     = 'DirectX Shader Cache (Windows)'
        'target.nvidia_dxcache'       = 'NVIDIA DXCache'
        'target.nvidia_glcache'       = 'NVIDIA GLCache'
        'target.amd_dx9cache'         = 'AMD DX9 Shader Cache'
        'target.amd_dxcache'          = 'AMD DX Shader Cache'
        'target.amd_dxccache'         = 'AMD DXC Shader Cache'
        'target.amd_vkcache'          = 'AMD Vulkan Cache'
        'target.amd_glcache'          = 'AMD OpenGL Cache'
        'target.amd_oglpcache'        = 'AMD OpenGL Cache (new)'
        'target.amd_dx9cache_ll'      = 'AMD DX9 Cache (LocalLow)'
        'target.amd_dxcache_ll'       = 'AMD DX Cache (LocalLow)'
        'target.amd_dxccache_ll'      = 'AMD DXC Cache (LocalLow)'
        'target.amd_vkcache_ll'       = 'AMD Vulkan Cache (LocalLow)'
        'target.amd_glcache_ll'       = 'AMD OpenGL Cache (LocalLow)'
        'target.amd_oglpcache_ll'     = 'AMD OpenGL Cache (LocalLow)'
        'target.windows_temp'         = 'Windows Temp'
        'target.pip_cache'            = 'pip cache'
        'target.npm_cache'            = 'npm cache'
        'target.go_build'             = 'Go build cache'
        'target.crash_dumps'          = 'Crash dumps'
        'target.inet_cache'           = 'Internet cache'
        'target.web_cache'            = 'Web cache'
        'target.intel_shader_cache'   = 'Intel shader cache'
        'target.cursor_cache'         = 'Cursor IDE cache'
        'target.cursor_cached_data'   = 'Cursor cached data'
        'target.cursor_code_cache'    = 'Cursor code cache'
        'target.vscode_cache'         = 'VS Code cache'
        'target.vscode_cached_data'   = 'VS Code cached data'
        'target.vscode_code_cache'    = 'VS Code code cache'
        'target.winget_installers'    = 'WinGet installers'
        'target.winget_cache'         = 'WinGet cache'
        'target.nuget_packages'       = 'NuGet package cache'
        'target.gradle_caches'        = 'Gradle caches'
        'target.cargo_registry'       = 'Cargo registry cache'
        'target.cargo_git'            = 'Cargo git checkouts'
        'target.pnpm_store'           = 'pnpm store'
        'target.yarn_cache'           = 'Yarn cache'
        'target.windows_disk_cleanup' = 'Windows Disk Cleanup'
    }
}

function Get-CleanupMsg {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [object[]]$Format
    )

    $table = $CleanupMessages[$CleanupLang]
    if (-not $table.ContainsKey($Key)) {
        $table = $CleanupMessages['en']
    }
    if (-not $table.ContainsKey($Key)) {
        return $Key
    }

    $message = $table[$Key]
    if ($Format -and @($Format).Count -gt 0) {
        $culture = if ($CleanupLang -eq 'ru') { 'ru-RU' } else { 'en-US' }
        return [string]::Format(
            [System.Globalization.CultureInfo]::GetCultureInfo($culture),
            $message,
            [object[]]$Format
        )
    }
    return $message
}

function Get-CleanupTargetName {
    param([string]$NameKey)

    $key = "target.$NameKey"
    $label = Get-CleanupMsg -Key $key
    if ($label -eq $key) {
        return $NameKey
    }
    return $label
}

function L {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$FormatArgs
    )

    if ($null -ne $FormatArgs -and @($FormatArgs).Count -gt 0) {
        return Get-CleanupMsg -Key $Key -Format $FormatArgs
    }
    return Get-CleanupMsg -Key $Key
}
