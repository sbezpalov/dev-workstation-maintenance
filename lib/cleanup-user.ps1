# User profile cleanup — reads config/cleanup.list (scope: user)

function Invoke-UserCleanup {
    $targets = Get-CleanupTargets -Scope 'user'
    $profiles = @(Get-UserProfilePaths)

    Write-CleanupLog ''
    Write-CleanupLog (L 'user.profile_cleanup')

    if ($profiles.Count -eq 0) {
        Write-CleanupLog (L 'user.no_profiles')
        return
    }

    Write-CleanupLog (L 'user.profiles_count' $profiles.Count $CleanupTier)

    foreach ($userHome in $profiles) {
        Write-CleanupLog ''
        Write-CleanupLog "--- $userHome ---"

        foreach ($target in $targets) {
            $paths = Resolve-UserCleanupPaths -UserHome $userHome -PathTemplate $target.Path
            foreach ($path in $paths) {
                $freed = Clear-FolderSafely -Path $path -Label $target.Name
                Add-CleanupStat -Category 'user' -Name $target.Name -FreedBytes $freed
            }
        }

        if ($ClearLooseFiles) {
            if ($DryRun) {
                Write-CleanupLog (L 'user.loose_dry')
            } else {
                Write-CleanupLog (L 'user.loose_clean')
                foreach ($pattern in $LooseFilePatterns) {
                    Get-ChildItem -LiteralPath $userHome -Filter $pattern -File -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
