param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptDir,
    [string]$CliOverride = '',
    [string]$OutFile = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $ScriptDir 'lib\i18n.ps1')

$projectIni = Join-Path $ScriptDir 'config\project.ini'
$cleanupIni = Join-Path $ScriptDir 'config\cleanup.ini'
$pref = if ($CliOverride) { $CliOverride } else { Get-ProjectLanguagePreference -ProjectIni $projectIni -FallbackIni $cleanupIni }
Initialize-ProjectLanguage -Override $pref

$lines = @("PROJECT_LANG=$ProjectLang")

$table = $ProjectMessages[$ProjectLang]
foreach ($key in ($table.Keys | Sort-Object)) {
    $varName = 'I18N_' + ($key -replace '\.', '_')
    $value = $table[$key] -replace '%', '%%' -replace '"', '""'
    $lines += "${varName}=$value"
}

if (-not $OutFile) {
    $lines | Write-Output
    return
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutFile, ($lines -join "`r`n"), $utf8NoBom)
