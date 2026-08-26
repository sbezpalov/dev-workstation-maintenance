param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptDir,
    [string]$CliOverride = '',
    [string]$OutFile = '',
    [string]$ApplyFile = '',
    [string]$ApplyDirectory = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $ScriptDir 'lib\i18n.ps1')

$projectIni = Join-Path $ScriptDir 'config\project.ini'
$cleanupIni = Join-Path $ScriptDir 'config\cleanup.ini'
$pref = if ($CliOverride) { $CliOverride } else { Get-ProjectLanguagePreference -ProjectIni $projectIni -FallbackIni $cleanupIni }
Initialize-ProjectLanguage -Override $pref

$pairs = [ordered]@{ PROJECT_LANG = $ProjectLang }

$table = $ProjectMessages[$ProjectLang]
foreach ($key in ($table.Keys | Sort-Object)) {
    $varName = 'I18N_' + ($key -replace '\.', '_')
    # Keep !placeholders! literal; ApplyFile escapes them for CMD delayed expansion.
    $value = $table[$key] -replace '%', '%%' -replace '"', '""'
    $pairs[$varName] = $value
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

if ($ApplyDirectory -and -not $ApplyFile) {
    $ApplyFile = Join-Path $ApplyDirectory ("proj_i18n_apply_{0}.cmd" -f [guid]::NewGuid().ToString('N'))
}

if ($OutFile) {
    $exportLines = foreach ($k in $pairs.Keys) { "$k=$($pairs[$k])" }
    [System.IO.File]::WriteAllText($OutFile, ($exportLines -join "`r`n"), $utf8NoBom)
}

if ($ApplyFile) {
    $apply = New-Object System.Collections.Generic.List[string]
    [void]$apply.Add('@echo off')
    foreach ($k in $pairs.Keys) {
        $v = $pairs[$k] -replace '\^', '^^' -replace '!', '^!'
        [void]$apply.Add(('set "{0}={1}"' -f $k, $v))
    }
    [System.IO.File]::WriteAllText($ApplyFile, ($apply -join "`r`n"), $utf8NoBom)
    if ($ApplyDirectory) { Write-Output $ApplyFile }
}

if (-not $OutFile -and -not $ApplyFile) {
    foreach ($k in $pairs.Keys) { Write-Output "$k=$($pairs[$k])" }
}
