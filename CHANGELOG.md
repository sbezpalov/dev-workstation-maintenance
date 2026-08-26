# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Windows CI and `tests/validate.ps1` for syntax, localization, config schema, path, and CMD smoke checks
- Explicit `--pause` option for the disk-cleanup launcher

### Changed

- WinGet operations now use exact package ID matching; all configured IDs were verified with WinGet 1.29.290 on 2026-08-26
- Maintenance accepts `auto` as an explicit CLI language and rejects unknown or incomplete arguments
- Disk-cleanup dry-runs no longer request UAC
- PATH refresh merges registry entries with the current session so version-manager and shim paths are preserved

### Fixed

- CMD help no longer leaks caret escaping around `|`
- Disk-cleanup launcher now expands localized variables, forwards exit codes, and accepts language options in any position
- `--skip-winget` no longer requires WinGet unless an optional WinGet app was requested
- Desktop-only optional app rows now follow the documented five-field schema
- Zero-valued localized summary fields are formatted correctly
- Concurrent CMD launches no longer collide on the temporary localization file

### Security

- Cleanup paths are constrained to their profile or `%SystemRoot%`, and reparse points are skipped
- WinGet package selection uses `--exact` to prevent ambiguous matches

## [1.0.0] - 2026-07-28

### Added

- SemVer baseline via root `VERSION` and `config/project.ini`
- English as the default language for docs and UI (`README.md`, `LANGUAGE=en`); Russian alternative: `README.ru.md` / `--language ru`
- Optional ChatGPT desktop (Microsoft Store) and Codex CLI (`--with-chatgpt`, `--with-codex-cli`)
- Community health: `SECURITY.md`, `CONTRIBUTING.md`, GitHub issue/PR templates
- `CHANGELOG.md`

### Fixed

- OpenRouter user-env registration no longer redirects `reg add` output (which could include secret values) into maintain logs

### Notes

- Desktop ChatGPT from the Store is a single OpenAI app (`OpenAI.Codex_*`) that already includes the Codex agent; only Codex CLI is a separate package

[1.0.0]: https://github.com/sbezpalov/dev-workstation-maintenance/releases/tag/v1.0.0
[Unreleased]: https://github.com/sbezpalov/dev-workstation-maintenance/compare/v1.0.0...HEAD
