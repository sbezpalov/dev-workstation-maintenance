# Disk cleanup orchestrator — modular cleanup for drive C:
# Config: config/cleanup.ini, config/cleanup.list
# i18n: ru-RU (system ru) | en-US (default)

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet('safe', 'developer', 'aggressive')]
    [string]$Tier,
    [ValidateSet('ru', 'en', 'ru-RU', 'en-US', 'auto', '')]
    [string]$Language
)

$ErrorActionPreference = 'Continue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path -Path $ScriptDir -ChildPath 'logs'

. (Join-Path -Path $ScriptDir -ChildPath 'lib\i18n.ps1')

$projectIni = Join-Path -Path $ScriptDir -ChildPath 'config\project.ini'
$cleanupIni = Join-Path -Path $ScriptDir -ChildPath 'config\cleanup.ini'
$langPreference = if ($Language) { $Language } else { Get-ProjectLanguagePreference -ProjectIni $projectIni -FallbackIni $cleanupIni }
Initialize-ProjectLanguage -Override $langPreference
$script:CleanupLang = $ProjectLang

function Test-IsAdministrator {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Import-CleanupConfig {
    $settings = @{
        CLEANUP_TIER        = 'developer'
        LANGUAGE            = 'auto'
        RUN_CLEANMGR        = $true
        CLEANMGR_SAGESET    = 65535
        CLEAR_RECYCLE_BIN   = $true
        CLEAR_LOOSE_FILES   = $true
    }

    if (Test-Path -LiteralPath $cleanupIni) {
        Get-Content -LiteralPath $cleanupIni -Encoding UTF8 | ForEach-Object {
            $line = $_.Trim()
            if (-not $line -or $line.StartsWith('#')) { return }
            $parts = $line -split '=', 2
            if ($parts.Count -lt 2) { return }
            $settings[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    if ($Tier) {
        $script:CleanupTier = $Tier.ToLowerInvariant()
    } else {
        $script:CleanupTier = ($settings['CLEANUP_TIER']).ToString().ToLowerInvariant()
    }

    if ($CleanupTier -notin @('safe', 'developer', 'aggressive')) {
        $script:CleanupTier = 'developer'
    }

    $script:RunCleanmgr = ($settings['RUN_CLEANMGR'] -eq '1')
    $script:CleanmgrSageset = [int]$settings['CLEANMGR_SAGESET']
    $script:ClearRecycleBin = ($settings['CLEAR_RECYCLE_BIN'] -eq '1')
    $script:ClearLooseFiles = ($settings['CLEAR_LOOSE_FILES'] -eq '1')
}

function Write-CleanupSummary {
    param(
        [long]$InitialFreeBytes,
        [long]$FinalFreeBytes
    )

    $diskDelta = $FinalFreeBytes - $InitialFreeBytes
    $drySuffix = if ($DryRun) { L 'summary.dry_run_suffix' } else { '' }

    Write-CleanupLog ''
    Write-CleanupLog '======================================'
    Write-CleanupLog (L 'summary.done')
    Write-CleanupLog (L 'summary.tier' $CleanupTier $drySuffix)

    if ($CleanupStats.Count -gt 0) {
        Write-CleanupLog ''
        Write-CleanupLog (L 'summary.by_category')
        $CleanupStats |
            Group-Object Category |
            ForEach-Object {
                $sum = ($_.Group | Measure-Object -Property FreedMB -Sum).Sum
                $catLabel = L "category.$($_.Name)"
                Write-CleanupLog (L 'summary.category_line' $catLabel ([math]::Round($sum, 2)))
            }
    }

    Write-CleanupLog ''
    Write-CleanupLog (L 'summary.tracked' (Format-SizeMB $CleanupFreedBytes))
    Write-CleanupLog (L 'summary.disk_delta' (Format-SizeMB $diskDelta) ([math]::Round($diskDelta / 1GB, 2)))
    Write-CleanupLog (L 'summary.free_on' $env:SystemDrive ([math]::Round($FinalFreeBytes / 1GB, 2)))
    if ($LogFile) {
        Write-CleanupLog (L 'summary.log' $LogFile)
    }
}

if (-not (Test-IsAdministrator)) {
    Write-Host (L 'uac.need_admin') -ForegroundColor Yellow
    Write-Host (L 'uac.prompt') -ForegroundColor Yellow

    $elevateArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $PSCommandPath
    )
    if ($DryRun) { $elevateArgs += '-DryRun' }
    if ($Tier) { $elevateArgs += @('-Tier', $Tier) }
    $elevateArgs += @('-Language', $CleanupLang)

    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $elevateArgs -Wait
    } catch {
        Write-Host (L 'uac.cancelled') -ForegroundColor Red
        exit 1
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogFile = Join-Path -Path $LogDir -ChildPath "clean_disk_$timestamp.log"
$script:DryRun = [bool]$DryRun
$script:CleanupStats = @()
$script:CleanupFreedBytes = 0

Import-CleanupConfig

. (Join-Path -Path $ScriptDir -ChildPath 'lib\cleanup-common.ps1')
. (Join-Path -Path $ScriptDir -ChildPath 'lib\cleanup-user.ps1')
. (Join-Path -Path $ScriptDir -ChildPath 'lib\cleanup-system.ps1')

$driveName = $env:SystemDrive.TrimEnd(':')
$initialFree = (Get-PSDrive -Name $driveName).Free

Write-CleanupLog '============================================================'
Write-CleanupLog (L 'start.header' $env:SystemDrive)
if ($DryRun) { Write-CleanupLog (L 'start.dry_run') }
Write-CleanupLog (L 'start.tier' $CleanupTier)
Write-CleanupLog '============================================================'

Invoke-UserCleanup
Invoke-SystemCleanup

$finalFree = (Get-PSDrive -Name $driveName).Free
Write-CleanupSummary -InitialFreeBytes $initialFree -FinalFreeBytes $finalFree
