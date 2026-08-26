[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Assert-ProjectCondition {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        [void]$failures.Add($Message)
    }
}

function Get-DataLines {
    param([string]$Path)
    return @(Get-Content -LiteralPath $Path -Encoding UTF8 | Where-Object {
        $trimmed = $_.Trim()
        $trimmed -and -not $trimmed.StartsWith('#')
    })
}

Write-Host '[validate] PowerShell syntax'
Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.ps1' | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null
    foreach ($parseError in @($errors)) {
        [void]$failures.Add("$($_.FullName):$($parseError.Extent.StartLineNumber): $($parseError.Message)")
    }
}

Write-Host '[validate] CMD line endings'
Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.cmd' | ForEach-Object {
    $batchText = [System.IO.File]::ReadAllText($_.FullName)
    Assert-ProjectCondition (-not [regex]::IsMatch($batchText, '(?<!\r)\n')) "CMD file must use CRLF line endings: $($_.FullName)"
}

Write-Host '[validate] Version consistency'
$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$projectVersionLine = Get-DataLines (Join-Path $repoRoot 'config\project.ini') |
    Where-Object { $_ -match '^VERSION=' } |
    Select-Object -First 1
$projectVersion = if ($projectVersionLine) { ($projectVersionLine -split '=', 2)[1].Trim() } else { '' }
Assert-ProjectCondition ($version -match '^\d+\.\d+\.\d+$') "VERSION is not SemVer: $version"
Assert-ProjectCondition ($version -eq $projectVersion) "VERSION ($version) differs from config/project.ini ($projectVersion)"

Write-Host '[validate] Localization parity'
. (Join-Path $repoRoot 'lib\i18n-data.ps1')
$ruKeys = @($ProjectMessages['ru'].Keys | Sort-Object)
$enKeys = @($ProjectMessages['en'].Keys | Sort-Object)
$keyDiff = @(Compare-Object -ReferenceObject $ruKeys -DifferenceObject $enKeys)
Assert-ProjectCondition ($keyDiff.Count -eq 0) "Russian and English localization keys differ: $($keyDiff | Out-String)"

Write-Host '[validate] Package configuration'
$packageRows = Get-DataLines (Join-Path $repoRoot 'config\packages.list')
$packageIds = New-Object System.Collections.Generic.List[string]
foreach ($row in $packageRows) {
    $parts = [regex]::Split($row, '\|')
    Assert-ProjectCondition ($parts.Count -ge 3 -and $parts.Count -le 4) "Invalid packages.list row: $row"
    if ($parts.Count -lt 3) { continue }
    Assert-ProjectCondition ($parts[0] -in @('upgrade', 'install', 'ensure')) "Invalid package action: $row"
    Assert-ProjectCondition (-not [string]::IsNullOrWhiteSpace($parts[1])) "Missing package ID: $row"
    if ($parts[0] -eq 'ensure') {
        Assert-ProjectCondition ($parts.Count -eq 4 -and -not [string]::IsNullOrWhiteSpace($parts[3])) "ensure requires a probe: $row"
    }
    [void]$packageIds.Add($parts[1])
}
$duplicatePackageIds = @($packageIds | Group-Object | Where-Object Count -gt 1)
Assert-ProjectCondition ($duplicatePackageIds.Count -eq 0) "Duplicate package IDs: $($duplicatePackageIds.Name -join ', ')"

$optionalSettings = @{}
foreach ($row in Get-DataLines (Join-Path $repoRoot 'config\optional.ini')) {
    $parts = $row -split '=', 2
    if ($parts.Count -eq 2) { $optionalSettings[$parts[0].Trim()] = $parts[1].Trim() }
}

$optionalRows = Get-DataLines (Join-Path $repoRoot 'config\optional-apps.list')
$optionalIds = New-Object System.Collections.Generic.List[string]
foreach ($row in $optionalRows) {
    $parts = [regex]::Split($row, '\|')
    Assert-ProjectCondition ($parts.Count -eq 5) "Invalid optional-apps.list row: $row"
    if ($parts.Count -ne 5) { continue }
    Assert-ProjectCondition ($optionalSettings.ContainsKey($parts[0])) "Optional flag is missing from optional.ini: $($parts[0])"
    Assert-ProjectCondition (-not [string]::IsNullOrWhiteSpace($parts[1])) "Missing optional app ID: $row"
    [void]$optionalIds.Add($parts[1])
}
$duplicateOptionalIds = @($optionalIds | Group-Object | Where-Object Count -gt 1)
Assert-ProjectCondition ($duplicateOptionalIds.Count -eq 0) "Duplicate optional app IDs: $($duplicateOptionalIds.Name -join ', ')"

Write-Host '[validate] Cleanup configuration'
foreach ($row in Get-DataLines (Join-Path $repoRoot 'config\cleanup.list')) {
    $parts = [regex]::Split($row, '\|')
    Assert-ProjectCondition ($parts.Count -eq 4) "Invalid cleanup.list row: $row"
    if ($parts.Count -ne 4) { continue }
    Assert-ProjectCondition ($parts[0] -in @('safe', 'developer', 'aggressive')) "Invalid cleanup tier: $row"
    Assert-ProjectCondition ($parts[1] -in @('user', 'system')) "Invalid cleanup scope: $row"
    Assert-ProjectCondition ($parts[2] -notmatch '(^|[\\/])\.\.([\\/]|$)') "Cleanup path contains parent traversal: $row"
    if ($parts[1] -eq 'system') {
        Assert-ProjectCondition ($parts[2].StartsWith('%SystemRoot%\', [System.StringComparison]::OrdinalIgnoreCase)) "System cleanup path must be below %SystemRoot%: $row"
    }
    foreach ($language in @('ru', 'en')) {
        Assert-ProjectCondition ($ProjectMessages[$language].ContainsKey("target.$($parts[3])")) "Missing $language cleanup label for target.$($parts[3])"
    }
}

$script:ScriptDir = $repoRoot
. (Join-Path $repoRoot 'lib\i18n.ps1')
Initialize-ProjectLanguage -Override 'en'
. (Join-Path $repoRoot 'lib\cleanup-common.ps1')
$testCleanupRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'dev-workstation-maintenance-test-root'
$testCleanupChild = Join-Path (Join-Path (Join-Path $testCleanupRoot 'AppData') 'Local') 'Temp'
$testCleanupEscape = Join-Path (Join-Path $testCleanupRoot '..') 'outside'
Assert-ProjectCondition (Test-PathWithinRoot -Path $testCleanupChild -Root $testCleanupRoot) 'Valid user cleanup path was rejected'
Assert-ProjectCondition (-not (Test-PathWithinRoot -Path $testCleanupEscape -Root $testCleanupRoot)) 'Parent traversal escaped a user profile root'
Assert-ProjectCondition (-not (Test-PathWithinRoot -Path $testCleanupRoot -Root $testCleanupRoot)) 'Cleanup root itself must not be accepted as a child path'

if ($env:OS -eq 'Windows_NT' -and $env:ComSpec) {
    Write-Host '[validate] CMD help smoke tests'
    $mainScript = Join-Path $repoRoot 'maintain-dev-workstation.cmd'
    $mainHelp = & $env:ComSpec /d /c "`"$mainScript`" --help" 2>&1
    Assert-ProjectCondition ($LASTEXITCODE -eq 0) "maintain-dev-workstation.cmd --help failed with $LASTEXITCODE"
    $mainHelpText = $mainHelp -join "`n"
    Assert-ProjectCondition ($mainHelpText.Contains('--language en|ru|auto')) 'Main help has an invalid language option'
    Assert-ProjectCondition (-not $mainHelpText.Contains('^^|')) 'Main help contains leaked caret escaping'

    $cleanupLauncher = Join-Path $repoRoot 'clean_disk.cmd'
    $cleanupHelp = & $env:ComSpec /d /c "`"$cleanupLauncher`" --language ru --help" 2>&1
    Assert-ProjectCondition ($LASTEXITCODE -eq 0) "clean_disk.cmd --help failed with $LASTEXITCODE"
    Assert-ProjectCondition (($cleanupHelp -join "`n").Contains('Использование:')) 'Russian cleanup launcher help was not rendered'

    $openClawInstaller = Join-Path $repoRoot 'install-openclaw.cmd'
    $openClawHelp = & $env:ComSpec /d /c "`"$openClawInstaller`" --quick --language ru --help" 2>&1
    Assert-ProjectCondition ($LASTEXITCODE -eq 0) "install-openclaw.cmd --help failed with $LASTEXITCODE"
    Assert-ProjectCondition (($openClawHelp -join "`n").Contains('install-openclaw.cmd')) 'OpenClaw help was not rendered'
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host "Validation failed ($($failures.Count)):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host '[validate] All checks passed.' -ForegroundColor Green
