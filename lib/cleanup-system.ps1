# System cleanup — paths from cleanup.list + cleanmgr + recycle bin

function Invoke-SystemPathCleanup {
    $targets = Get-CleanupTargets -Scope 'system'

    Write-CleanupLog ''
    Write-CleanupLog (L 'system.path_cleanup')

    foreach ($target in $targets) {
        $path = Expand-SystemPath -PathTemplate $target.Path
        $freed = Clear-FolderSafely -Path $path -Label $target.Name
        Add-CleanupStat -Category 'system' -Name $target.Name -FreedBytes $freed
    }
}

function Invoke-WindowsDiskCleanup {
    if (-not $RunCleanmgr) {
        Write-CleanupLog (L 'system.cleanmgr_disabled')
        return
    }

    $cleanmgr = Join-Path -Path $env:SystemRoot -ChildPath 'System32\cleanmgr.exe'
    if (-not (Test-Path -LiteralPath $cleanmgr)) {
        Write-CleanupLog (L 'system.cleanmgr_not_found')
        return
    }

    $drive = "$($env:SystemDrive)\"
    Write-CleanupLog ''
    Write-CleanupLog (L 'system.cleanmgr_start' $CleanmgrSageset $drive)

    if ($DryRun) {
        Write-CleanupLog (L 'system.cleanmgr_dry' $CleanmgrSageset $drive)
        return
    }

    $spaceBefore = (Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')).Free

    $processArgs = @("/sagerun:$CleanmgrSageset", "/d", $drive)
    Start-Process -FilePath $cleanmgr -ArgumentList $processArgs -Wait -NoNewWindow -ErrorAction SilentlyContinue | Out-Null

    $spaceAfter = (Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')).Free
    $freed = [math]::Max(0, $spaceAfter - $spaceBefore)
    $cleanmgrName = Get-CleanupTargetName -NameKey 'windows_disk_cleanup'
    if ($freed -gt 0) {
        Write-CleanupLog (L 'system.cleanmgr_ok' (Format-SizeMB $freed))
        Add-CleanupStat -Category 'system' -Name $cleanmgrName -FreedBytes $freed
    } else {
        Write-CleanupLog (L 'system.cleanmgr_no_change')
        Write-CleanupLog (L 'system.cleanmgr_setup')
    }
}

function Invoke-RecycleBinCleanup {
    if (-not $ClearRecycleBin) {
        Write-CleanupLog (L 'system.recycle_disabled')
        return
    }

    Write-CleanupLog ''
    Write-CleanupLog (L 'system.recycle_header')

    if ($DryRun) {
        Write-CleanupLog (L 'system.recycle_dry')
        return
    }

    try {
        $driveLetter = $env:SystemDrive.TrimEnd(':')
        Clear-RecycleBin -DriveLetter $driveLetter -Force -ErrorAction Stop
        Write-CleanupLog (L 'system.recycle_ok')
    } catch {
        try {
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-CleanupLog (L 'system.recycle_ok')
        } catch {
            Write-CleanupLog (L 'system.recycle_warn' $_.Exception.Message)
        }
    }
}

function Invoke-SystemCleanup {
    Invoke-SystemPathCleanup
    Invoke-WindowsDiskCleanup
    Invoke-RecycleBinCleanup
}
