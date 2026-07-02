# Project i18n — shared by PowerShell modules and CMD export (lib/i18n-export.ps1)

. (Join-Path $PSScriptRoot 'i18n-data.ps1')

$script:ProjectLang = 'en'
$script:CleanupLang = 'en'

function Resolve-ProjectLanguage {
    param([string]$Override)

    if ($Override) {
        switch -Regex ($Override.Trim()) {
            '^(ru|ru-RU|ru-ru)$' { return 'ru' }
            '^(en|en-US|en-us)$' { return 'en' }
            '^auto$' { break }
            default { break }
        }
    }

    $culture = [System.Globalization.CultureInfo]::InstalledUICulture
    if ($culture.TwoLetterISOLanguageName -eq 'ru') {
        return 'ru'
    }
    return 'en'
}

function Read-IniLanguageValue {
    param([string]$IniFile)

    if (-not $IniFile -or -not (Test-Path -LiteralPath $IniFile)) {
        return $null
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

    return $null
}

function Get-ProjectLanguagePreference {
    param(
        [string]$ProjectIni,
        [string]$FallbackIni
    )

    $fromProject = Read-IniLanguageValue -IniFile $ProjectIni
    if ($fromProject) {
        return $fromProject
    }

    $fromFallback = Read-IniLanguageValue -IniFile $FallbackIni
    if ($fromFallback) {
        return $fromFallback
    }

    return 'auto'
}

function Initialize-ProjectLanguage {
    param([string]$Override)

    $script:ProjectLang = Resolve-ProjectLanguage -Override $Override
    $script:CleanupLang = $ProjectLang
}

function Get-ProjectMsg {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [object[]]$Format
    )

    $table = $ProjectMessages[$ProjectLang]
    if (-not $table.ContainsKey($Key)) {
        $table = $ProjectMessages['en']
    }
    if (-not $table.ContainsKey($Key)) {
        return $Key
    }

    $message = $table[$Key]
    if ($Format -and @($Format).Count -gt 0) {
        $culture = if ($ProjectLang -eq 'ru') { 'ru-RU' } else { 'en-US' }
        return [string]::Format(
            [System.Globalization.CultureInfo]::GetCultureInfo($culture),
            $message,
            [object[]]$Format
        )
    }
    return $message
}

function Get-ProjectTargetName {
    param([string]$NameKey)

    $key = "target.$NameKey"
    $label = Get-ProjectMsg -Key $key
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
        return Get-ProjectMsg -Key $Key -Format $FormatArgs
    }
    return Get-ProjectMsg -Key $Key
}

function Get-CleanupMsg {
    param(
        [string]$Key,
        [object[]]$Format
    )
    Get-ProjectMsg -Key $Key -Format $Format
}

function Get-CleanupTargetName {
    param([string]$NameKey)
    Get-ProjectTargetName -NameKey $NameKey
}

function Get-CleanupLanguagePreference {
    param([string]$IniFile)
    Get-ProjectLanguagePreference -FallbackIni $IniFile
}

function Initialize-CleanupLanguage {
    param([string]$Override)
    Initialize-ProjectLanguage -Override $Override
    $script:CleanupLang = $ProjectLang
}
