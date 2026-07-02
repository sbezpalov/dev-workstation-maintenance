# Скрипт очистки диска C: от временных файлов и кэша
# Обрабатывает все папки-профили в C:\Users + системные temp-папки.
# При необходимости запрашивает права администратора через UAC.

$ErrorActionPreference = 'Continue'

function Test-IsAdministrator {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Для очистки всех профилей нужны права администратора." -ForegroundColor Yellow
    Write-Host "Запрос подтверждения UAC..." -ForegroundColor Yellow

    $elevateArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $PSCommandPath
    )

    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $elevateArgs -Wait
    } catch {
        Write-Host "Запуск от имени администратора отменён." -ForegroundColor Red
        exit 1
    }
    exit 0
}

$UsersRoot = Join-Path -Path $env:SystemDrive -ChildPath 'Users'
$ExcludedUserFolders = @('Public', 'Default', 'Default User', 'All Users')

$UserCacheRelativePaths = @(
    'AppData\Local\Temp',
    'AppData\Local\pip\cache',
    'AppData\Local\npm-cache',
    'AppData\Local\go-build',
    'AppData\Local\CrashDumps'
)

# Кэш шейдеров GPU: Windows D3DSCache + NVIDIA + AMD/ATI (Local и LocalLow)
# Источники: NVIDIA driver, AMD Adrenalin (DxCache/DxcCache/VkCache), Windows DirectX
$GpuShaderCacheRelativePaths = @(
    'AppData\Local\D3DSCache',
    'AppData\Local\NVIDIA\DXCache',
    'AppData\Local\NVIDIA\GLCache'
)
foreach ($amdCache in @('Dx9Cache', 'DxCache', 'DxcCache', 'VkCache', 'GLCache', 'OglpCache')) {
    $GpuShaderCacheRelativePaths += "AppData\Local\AMD\$amdCache"
    $GpuShaderCacheRelativePaths += "AppData\LocalLow\AMD\$amdCache"
}

$LooseFilePatterns = @('*.tmp', '*.dmp', '*.crash')

function Clear-FolderSafely {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        Write-Host "Папка не найдена (пропуск): $Path" -ForegroundColor Gray
        return
    }

    Write-Host "Очистка папки: $Path" -ForegroundColor Cyan
    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            # Файл занят другой программой - пропускаем
        }
    }
}

function Test-UserProfileDirectory {
    param([string]$UserHome)

    $appDataPath = Join-Path -Path $UserHome -ChildPath 'AppData'
    $ntuserPath = Join-Path -Path $UserHome -ChildPath 'ntuser.dat'

    return (Test-Path -LiteralPath $appDataPath -ErrorAction SilentlyContinue) -or
           (Test-Path -LiteralPath $ntuserPath -ErrorAction SilentlyContinue)
}

function Get-UserProfilePaths {
    $profiles = @{}

    if (-not (Test-Path -LiteralPath $UsersRoot -ErrorAction SilentlyContinue)) {
        return @()
    }

    # Все папки в C:\Users (WMI часто видит только активный профиль)
    Get-ChildItem -LiteralPath $UsersRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $ExcludedUserFolders } |
        ForEach-Object {
            if (Test-UserProfileDirectory -UserHome $_.FullName) {
                $profiles[$_.FullName.ToLowerInvariant()] = $_.FullName
            }
        }

    # Дополнительно — профили из WMI, если папка ещё не в списке
    Get-CimInstance -ClassName Win32_UserProfile -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.Special -and
            $_.LocalPath -and
            $_.LocalPath.StartsWith($UsersRoot, [System.StringComparison]::OrdinalIgnoreCase)
        } |
        ForEach-Object {
            if (Test-Path -LiteralPath $_.LocalPath -ErrorAction SilentlyContinue) {
                $profiles[$_.LocalPath.ToLowerInvariant()] = $_.LocalPath
            }
        }

    return $profiles.Values | Sort-Object
}

function Clear-UserCaches {
    param([string]$UserHome)

    Write-Host ""
    Write-Host "--- Пользователь: $UserHome ---" -ForegroundColor Green

    foreach ($relativePath in $UserCacheRelativePaths) {
        Clear-FolderSafely -Path (Join-Path -Path $UserHome -ChildPath $relativePath)
    }

    Write-Host "Кэш GPU: DirectX (D3DSCache), NVIDIA, AMD/ATI..." -ForegroundColor Cyan
    foreach ($relativePath in $GpuShaderCacheRelativePaths) {
        Clear-FolderSafely -Path (Join-Path -Path $UserHome -ChildPath $relativePath)
    }

    Write-Host "Поиск и удаление *.tmp, *.dmp, *.crash в корне профиля..." -ForegroundColor Cyan
    foreach ($pattern in $LooseFilePatterns) {
        Get-ChildItem -LiteralPath $UserHome -Filter $pattern -File -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

$initialSpace = (Get-PSDrive C).Free
Write-Host "=== Начало очистки диска C: (администратор) ===" -ForegroundColor Green

$userProfiles = @(Get-UserProfilePaths)
if ($userProfiles.Count -eq 0) {
    Write-Host "Профили пользователей в $UsersRoot не найдены." -ForegroundColor Yellow
} else {
    Write-Host "Найдено профилей: $($userProfiles.Count)" -ForegroundColor Gray
    foreach ($userHome in $userProfiles) {
        Clear-UserCaches -UserHome $userHome
    }
}

Write-Host ""
Write-Host "--- Системные папки ---" -ForegroundColor Green
Clear-FolderSafely -Path (Join-Path -Path $env:SystemRoot -ChildPath 'Temp')

$finalSpace = (Get-PSDrive C).Free
$freedSpaceMB = [math]::Round(($finalSpace - $initialSpace) / 1MB, 2)
$freedSpaceGB = [math]::Round(($finalSpace - $initialSpace) / 1GB, 2)
$availableGB = [math]::Round($finalSpace / 1GB, 2)

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "Очистка завершена!" -ForegroundColor Green
Write-Host "Освобождено: $freedSpaceMB МБ ($freedSpaceGB ГБ)" -ForegroundColor Yellow
Write-Host "Доступно на диске C: $availableGB ГБ" -ForegroundColor Yellow
