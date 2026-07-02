# Shared helpers for disk cleanup modules

if (-not $ScriptDir) { throw 'ScriptDir must be set before dot-sourcing cleanup-common.ps1' }

$CleanupTierRanks = @{
    safe       = 0
    developer  = 1
    aggressive = 2
}

$ExcludedUserFolders = @('Public', 'Default', 'Default User', 'All Users')
$LooseFilePatterns = @('*.tmp', '*.dmp', '*.crash')

function Write-CleanupLog {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host ''
        if ($LogFile) { Add-Content -LiteralPath $LogFile -Value '' -Encoding UTF8 }
        return
    }

    Write-Host $Message
    if ($LogFile) {
        Add-Content -LiteralPath $LogFile -Value $Message -Encoding UTF8
    }
}

function Format-SizeMB {
    param([long]$Bytes)
    return [math]::Round($Bytes / 1MB, 2)
}

function Test-TierIncluded {
    param([string]$MinTier)

    if (-not $CleanupTierRanks.ContainsKey($MinTier)) { return $false }
    if (-not $CleanupTierRanks.ContainsKey($CleanupTier)) { return $false }
    return $CleanupTierRanks[$CleanupTier] -ge $CleanupTierRanks[$MinTier]
}

function Expand-SystemPath {
    param([string]$PathTemplate)

    $path = $PathTemplate
    $path = $path -replace '%SystemRoot%', $env:SystemRoot
    $path = $path -replace '%SystemDrive%', $env:SystemDrive
    return $path
}

function Get-FolderSizeBytes {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        return 0
    }

    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum

    if ($null -eq $sum) { return 0 }
    return [long]$sum
}

function Resolve-UserCleanupPaths {
    param(
        [string]$UserHome,
        [string]$PathTemplate
    )

    if ($PathTemplate -notmatch '\*') {
        return @(Join-Path -Path $UserHome -ChildPath $PathTemplate)
    }

    $starIndex = $PathTemplate.IndexOf('*')
    $leftPart = $PathTemplate.Substring(0, $starIndex)
    $rightPart = $PathTemplate.Substring($starIndex + 1).TrimStart('\')

    $lastSlash = $leftPart.LastIndexOf('\')
    if ($lastSlash -lt 0) {
        return @()
    }

    $parentRel = $leftPart.Substring(0, $lastSlash)
    $namePrefix = $leftPart.Substring($lastSlash + 1)

    $parentPath = Join-Path -Path $UserHome -ChildPath $parentRel
    if (-not (Test-Path -LiteralPath $parentPath -ErrorAction SilentlyContinue)) {
        return @()
    }

    $resolved = @()
    Get-ChildItem -LiteralPath $parentPath -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "${namePrefix}*" } |
        ForEach-Object {
            if ($rightPart) {
                $resolved += Join-Path -Path $_.FullName -ChildPath $rightPart
            } else {
                $resolved += $_.FullName
            }
        }

    return $resolved
}

function Clear-FolderSafely {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        Write-CleanupLog (L 'skip.not_found' $Label)
        return 0
    }

    $sizeBefore = Get-FolderSizeBytes -Path $Path
    $sizeLabel = Format-SizeMB $sizeBefore

    if ($DryRun) {
        Write-CleanupLog (L 'dry_run.folder' $Label $Path $sizeLabel)
        return 0
    }

    Write-CleanupLog (L 'clean.folder' $Label $Path $sizeLabel)
    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            # Locked files are skipped
        }
    }

    $sizeAfter = Get-FolderSizeBytes -Path $Path
    $freed = [math]::Max(0, $sizeBefore - $sizeAfter)
    if ($freed -gt 0) {
        Write-CleanupLog (L 'ok.freed' $Label (Format-SizeMB $freed))
    }
    return [long]$freed
}

function Get-CleanupTargets {
    param([string]$Scope)

    $listFile = Join-Path -Path $ScriptDir -ChildPath 'config\cleanup.list'
    if (-not (Test-Path -LiteralPath $listFile)) {
        throw (L 'error.list_not_found' $listFile)
    }

    $targets = @()
    Get-Content -LiteralPath $listFile -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }

        $parts = $line -split '\|', 4
        if ($parts.Count -lt 4) { return }

        $minTier = $parts[0].Trim().ToLowerInvariant()
        $itemScope = $parts[1].Trim().ToLowerInvariant()
        $path = $parts[2].Trim()
        $nameKey = $parts[3].Trim()

        if ($itemScope -ne $Scope) { return }
        if (-not (Test-TierIncluded -MinTier $minTier)) { return }

        $targets += [PSCustomObject]@{
            MinTier = $minTier
            Scope   = $itemScope
            Path    = $path
            NameKey = $nameKey
            Name    = (Get-CleanupTargetName -NameKey $nameKey)
        }
    }

    return $targets
}

function Test-UserProfileDirectory {
    param([string]$UserHome)

    $appDataPath = Join-Path -Path $UserHome -ChildPath 'AppData'
    $ntuserPath = Join-Path -Path $UserHome -ChildPath 'ntuser.dat'

    return (Test-Path -LiteralPath $appDataPath -ErrorAction SilentlyContinue) -or
           (Test-Path -LiteralPath $ntuserPath -ErrorAction SilentlyContinue)
}

function Get-UserProfilePaths {
    $usersRoot = Join-Path -Path $env:SystemDrive -ChildPath 'Users'
    $profiles = @{}

    if (-not (Test-Path -LiteralPath $usersRoot -ErrorAction SilentlyContinue)) {
        return @()
    }

    Get-ChildItem -LiteralPath $usersRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $ExcludedUserFolders } |
        ForEach-Object {
            if (Test-UserProfileDirectory -UserHome $_.FullName) {
                $profiles[$_.FullName.ToLowerInvariant()] = $_.FullName
            }
        }

    Get-CimInstance -ClassName Win32_UserProfile -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.Special -and
            $_.LocalPath -and
            $_.LocalPath.StartsWith($usersRoot, [System.StringComparison]::OrdinalIgnoreCase)
        } |
        ForEach-Object {
            if (Test-Path -LiteralPath $_.LocalPath -ErrorAction SilentlyContinue) {
                $profiles[$_.LocalPath.ToLowerInvariant()] = $_.LocalPath
            }
        }

    return $profiles.Values | Sort-Object
}

function Add-CleanupStat {
    param(
        [string]$Category,
        [string]$Name,
        [long]$FreedBytes
    )

    if ($FreedBytes -le 0) { return }

    $script:CleanupStats += [PSCustomObject]@{
        Category = $Category
        Name     = $Name
        FreedMB  = (Format-SizeMB $FreedBytes)
    }
    $script:CleanupFreedBytes += $FreedBytes
}
