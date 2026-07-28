# Security Policy

**English** · [Русский](SECURITY.ru.md)

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems.

Report privately via one of:

1. [GitHub Security Advisories](https://github.com/sbezpalov/dev-workstation-maintenance/security/advisories/new) (preferred)
2. Email the maintainer listed in the repository profile / [Author](README.md#author)

Include:

- Affected version (`VERSION` file / `config/project.ini`)
- Description and impact
- Steps to reproduce (or a minimal PoC)
- Whether the issue is already public elsewhere

You should receive an acknowledgement within **7 days**. We aim to publish a fix or mitigation guidance as soon as practical.

## What this project handles

This repository is a **local Windows maintenance toolkit** (`cmd` / PowerShell / `winget`). It may:

- Install or upgrade software with administrator rights
- Read API keys from `config/secrets.env` or CLI flags
- Write environment variables under `HKCU\Environment`
- Delete caches and temp files on the system drive during cleanup

### Secrets

- Store keys only in `config/secrets.env` (gitignored) or pass them via CLI for a single run
- Prefer `secrets.env.example` as the template — never commit real values
- Logs under `logs/` must not contain secret values; if you find a leak, report it as a vulnerability
- Rotate any key that may have appeared in a shell history, screenshot, or shared log

### Elevated execution

- Prefer reviewing `--dry-run` / `-DryRun` output before applying changes
- Run machine-scoped `winget` and full-profile disk cleanup only when you intend to elevate (UAC)
- Scheduled task registration (`register-scheduled-task.cmd`) should be done consciously as Administrator

## Out of scope

- Vulnerabilities in third-party packages installed by `winget` / npm / pip (report upstream)
- Local misconfiguration (weak Windows account, shared admin session, world-readable `secrets.env`)
