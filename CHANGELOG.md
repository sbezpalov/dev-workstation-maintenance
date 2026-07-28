# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-28

### Added

- SemVer baseline via root `VERSION` and `config/project.ini`
- Optional ChatGPT desktop (Microsoft Store) and Codex CLI (`--with-chatgpt`, `--with-codex-cli`)
- English documentation: `README.en.md`
- Community health: `SECURITY.md`, `CONTRIBUTING.md`, GitHub issue/PR templates
- `CHANGELOG.md`

### Fixed

- OpenRouter user-env registration no longer redirects `reg add` output (which could include secret values) into maintain logs

### Notes

- Desktop ChatGPT from the Store is a single OpenAI app (`OpenAI.Codex_*`) that already includes the Codex agent; only Codex CLI is a separate package

[1.0.0]: https://github.com/sbezpalov/dev-workstation-maintenance/releases/tag/v1.0.0
