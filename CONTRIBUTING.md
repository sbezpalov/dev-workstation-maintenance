# Contributing

**English** · [Русский](CONTRIBUTING.ru.md)

Thanks for helping improve **Dev Workstation Maintenance**.

## Before you start

1. Read [README.md](README.md) and [SECURITY.md](SECURITY.md)
2. Search existing issues / PRs to avoid duplicates
3. For security issues, follow [SECURITY.md](SECURITY.md) — do **not** file a public issue

## Development setup

```cmd
git clone https://github.com/sbezpalov/dev-workstation-maintenance.git
cd dev-workstation-maintenance
copy config\secrets.env.example config\secrets.env
```

- Windows 11 (or Windows 10 with App Installer / `winget`)
- Do not commit `config/secrets.env` or anything under `logs/`
- Prefer `--dry-run` / `-DryRun` while testing

## How to contribute

### Bugs

Open an issue with:

- OS build and whether you ran elevated
- Exact command line
- Relevant log excerpt from `logs/` **with secrets redacted**

### Features

Describe the problem, the proposed flag/config change, and whether it fits the existing `cmd` + `winget` + optional PowerShell model.

### Pull requests

1. Branch from the default branch
2. Keep changes focused (one concern per PR)
3. Update docs when behavior or flags change (`README.md`, `README.ru.md`, and i18n strings in `lib/i18n-data.ps1` when user-facing text changes)
4. Bump `VERSION` + `config/project.ini` `VERSION` and add a [CHANGELOG.md](CHANGELOG.md) entry for user-visible changes
5. Fill in the PR template

## Coding guidelines

- Match existing style: readable `cmd` / PowerShell, clear log messages, no clever one-liners
- User-facing strings go through i18n (`lib/i18n-data.ps1`) for both `ru` and `en`
- Optional AI apps belong in `config/optional-apps.list` + flags in `maintain-dev-workstation.cmd` / `config/optional.ini`
- Never log secret values (API keys, tokens). Redirecting commands that echo secrets into `logs/` is a bug
- Do not add telemetry or phone-home behavior

## Commit messages

Short, imperative, focused on **why** (examples: `fix: stop writing OpenRouter key to maintain logs`, `docs: add English README`).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
