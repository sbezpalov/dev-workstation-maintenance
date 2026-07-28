# Dev Workstation Maintenance

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**English** · [Русский](README.ru.md)

Automated developer workstation maintenance for **Windows 11**.

Community docs: [CONTRIBUTING](CONTRIBUTING.md) · [SECURITY](SECURITY.md) · [CHANGELOG](CHANGELOG.md)

The script updates tools via `winget`, maintains **Python/pip** and **npm** ecosystems, optionally installs **OpenClaw** and configures **OpenRouter**, and cleans disk caches and temp files. The main maintenance flow runs on **cmd.exe**; disk cleanup uses **PowerShell 5+** (built into Windows).

Python is required for IDEs and AI tools (Cursor, Antigravity, Claude Code, ChatGPT desktop, Codex CLI, Perplexity, MCP servers, VS Code extensions). Detection uses **Python Install Manager** (`py`) and ignores the Store stub under `WindowsApps`.

Script UI is localized: **English** (default) and **Russian** (`en` / `ru`). Optional `auto` follows the Windows UI language.

Current project version: **1.0.0** (see [`VERSION`](VERSION); also `VERSION` in `config/project.ini`).

License: **MIT** — see [LICENSE](LICENSE).

## Features

### Maintenance (`maintain-dev-workstation.cmd`)

- Sequential `winget` package processing (avoids MSI lock contention)
- Default install scope is **machine-wide** (`--scope machine`, all users); see `WINGET_SCOPE` in `config/project.ini`
- Three modes in `packages.list`: `upgrade` / `install` / `ensure` (does not duplicate external Python/PHP installs)
- pip upgrade for outdated packages + `pip check` (via `py -3` or a real `python`)
- npm self-update and global package update + `npm doctor`
- Health checks: Python, pip, Node, npm, Git, Go, PHP, PowerShell, gh, VS Code, OpenClaw
- Optional: AI apps via winget (Cursor, Antigravity, Claude, ChatGPT, Codex CLI, Perplexity and IDE/CLI variants)
- Optional: OpenClaw (official `install.ps1` or npm)
- Optional: OpenRouter (API key, env vars, CLI)
- Logs under `/logs/` (directory is in `.gitignore`, not published)
- Monthly run via `schtasks`

### Disk cleanup (`clean_disk.cmd` / `clean_disk.ps1`)

- Modular system-drive cleanup for **all profiles** under `C:\Users\*`
- Three tiers: `safe` → `developer` → `aggressive` (each includes the previous)
- GPU caches: NVIDIA (DXCache, GLCache), AMD (DxCache, DxcCache, VkCache, GLCache, OglpCache), Windows D3DSCache
- Dev tool caches: pip, npm, Go, Cursor, VS Code, WinGet, NuGet, Gradle, Cargo, pnpm, Yarn
- Optional: Windows Disk Cleanup (`cleanmgr`), Recycle Bin empty
- `-DryRun` mode, log under `logs/`
- Requests administrator rights (UAC) to clean all profiles

### Localization (i18n)

- Languages: `en` (default), `ru`, `auto` (follow Windows UI language)
- Default setting: `LANGUAGE=en` in `config/project.ini`
- CLI override: `--language en|ru` (CMD) or `-Language en|ru` (PowerShell)
- Localized user-facing messages: maintenance, OpenClaw, OpenRouter, optional apps, disk cleanup, scheduler

## Requirements

- Windows 11 (or Windows 10 with [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1))
- `winget` on PATH
- For `WINGET_SCOPE=machine` (default): run **as Administrator** — otherwise some packages fall back without `--scope`
- For the pip block: Python via `py` (Install Manager) or a real `python` on PATH (not the Store stub); if missing, `ensure` installs `Python.Python.3.14`
- For the npm block: Node.js
- For OpenClaw installer and disk cleanup: PowerShell 5+ (built into Windows)
- To clean all profiles: administrator rights

## Quick start

```cmd
git clone https://github.com/sbezpalov/dev-workstation-maintenance.git
cd dev-workstation-maintenance

:: Preview without changes
maintain-dev-workstation.cmd --dry-run

:: Full maintenance
maintain-dev-workstation.cmd

:: Disk cleanup (dry-run, tier from config\cleanup.ini)
clean_disk.cmd -DryRun
```

## Usage

### Maintenance

```cmd
maintain-dev-workstation.cmd [options]
```

| Flag | Description |
|------|-------------|
| `--dry-run` | Show plan without applying changes |
| `--skip-winget` | Skip winget updates |
| `--skip-pip` | Skip pip upgrade / check |
| `--skip-npm` | Skip npm update / doctor |
| `--with-cursor` | Install / upgrade Cursor IDE |
| `--with-antigravity` | Install / upgrade Antigravity IDE |
| `--with-antigravity-cli` | Install / upgrade Antigravity CLI |
| `--with-claude` | Install / upgrade Claude (desktop) |
| `--with-claude-code` | Install / upgrade Claude Code CLI |
| `--with-chatgpt` | Install / upgrade ChatGPT desktop (Microsoft Store; already includes Codex) |
| `--with-codex-cli` | Install / upgrade Codex CLI (separate terminal agent) |
| `--with-perplexity` | Install / upgrade Perplexity |
| `--with-perplexity-comet` | Install / upgrade Perplexity Comet |
| `--with-ai-apps` | All optional AI apps above |
| `--with-openclaw` | Install OpenClaw |
| `--openclaw-onboard` | Full OpenClaw install with onboarding |
| `--openclaw-npm` | OpenClaw via npm instead of install.ps1 |
| `--with-openrouter` | Configure OpenRouter + CLI |
| `--openrouter-key KEY` | OpenRouter API key (`sk-or-v1-...`) |
| `--language en\|ru` | UI language (default: `en`) |
| `--scope machine\|user\|auto` | winget scope: machine / user / let winget decide (default: `machine`) |
| `--help` | Show help |

### Disk cleanup

```cmd
clean_disk.cmd [options]
```

| Parameter | Description |
|-----------|-------------|
| `-DryRun` | Show plan without deleting |
| `-Tier safe\|developer\|aggressive` | Cleanup tier (overrides `config\cleanup.ini`) |
| `-Language en\|ru` | UI language |
| `--language en\|ru` | Same (for the CMD launcher) |

Cleanup tiers:

| Tier | What is removed |
|------|-----------------|
| `safe` | Temp, GPU shader caches (NVIDIA / AMD / Windows), `*.tmp` / `*.dmp` in profile roots |
| `developer` | + pip, npm, Go, IDE (Cursor, VS Code), WinGet, Internet / Web cache |
| `aggressive` | + NuGet, Gradle, Cargo, pnpm, Yarn (will re-download on next use) |

### OpenClaw

```cmd
install-openclaw.cmd [--quick] [--language en|ru]
```

| Flag | Description |
|------|-------------|
| `--quick` | Install without interactive onboarding |
| `--language en\|ru` | Message language |

### Examples

```cmd
:: Dev tools only
maintain-dev-workstation.cmd

:: Russian UI
maintain-dev-workstation.cmd --language ru --dry-run

:: AI IDE and desktop apps (no OpenClaw)
maintain-dev-workstation.cmd --with-cursor --with-claude-code --with-perplexity

:: All AI apps from optional-apps.list
maintain-dev-workstation.cmd --with-ai-apps

:: OpenClaw + OpenRouter
maintain-dev-workstation.cmd --with-openclaw --with-openrouter --openrouter-key sk-or-v1-XXX

:: Official OpenClaw installer separately
install-openclaw.cmd
install-openclaw.cmd --quick

:: Disk cleanup: aggressive tier, dry-run
clean_disk.cmd -DryRun -Tier aggressive

:: Cleanup with Russian UI
clean_disk.cmd --language ru -DryRun
```

## Configuration

### `config/project.ini`

Project-wide settings:

```ini
# UI language: en | ru | auto  (default: en)
LANGUAGE=en

# SemVer (also in root VERSION file)
VERSION=1.0.0

# winget: machine | user | auto
# machine = all users on this computer (default; usually needs Administrator)
WINGET_SCOPE=machine
```

### `config/packages.list`

winget package list. Format: `ACTION|WINGET_ID|DISPLAY_NAME[|PROBE]`

Current base stack:

```
upgrade|OpenJS.NodeJS.LTS|Node.js LTS
ensure|Python.Python.3.14|Python 3.14|py
upgrade|Microsoft.PowerShell|PowerShell 7
install|GoLang.Go|Go
upgrade|Microsoft.VisualStudioCode|Visual Studio Code
ensure|PHP.PHP.NTS.8.5|PHP 8.5 NTS|php
upgrade|Git.Git|Git
upgrade|GitHub.cli|GitHub CLI
```

| ACTION | Behavior |
|--------|----------|
| `upgrade` | `winget upgrade` (package expected from winget) |
| `install` | `winget install` (if not present) |
| `ensure` | if `PROBE` is on PATH and works — skip (externally managed); otherwise `winget install` |

**Why `ensure`:** Python is often installed via **Python Install Manager** (`py`), PHP manually (`C:\Program Files\PHP\...`). The script does not place a second copy next to a working install.

### `config/optional.ini`

```ini
# CLI agents
INSTALL_OPENCLAW=0
INSTALL_OPENROUTER=0
OPENCLAW_ONBOARD=0
OPENCLAW_INSTALL_METHOD=installer
OPENROUTER_CLI_PACKAGE=@openrouter/cli

# AI desktop / IDE (winget)
INSTALL_CURSOR=0
INSTALL_ANTIGRAVITY=0
INSTALL_ANTIGRAVITY_CLI=0
INSTALL_CLAUDE_DESKTOP=0
INSTALL_CLAUDE_CODE=0
INSTALL_CHATGPT=0
INSTALL_CODEX_CLI=0
INSTALL_PERPLEXITY=0
INSTALL_PERPLEXITY_COMET=0
```

### `config/optional-apps.list`

AI desktop / IDE apps for winget. Format: `FLAG|WINGET_ID|DISPLAY_NAME|CLI_TOOL|CLI_CMD`

```
INSTALL_CURSOR|Anysphere.Cursor|Cursor|cursor|cursor --version
INSTALL_CLAUDE_CODE|Anthropic.ClaudeCode|Claude Code|claude|claude --version
INSTALL_CHATGPT|9PLM9XGG6VKS|ChatGPT (incl. Codex)|||
INSTALL_CODEX_CLI|OpenAI.Codex|Codex CLI|codex|codex --version
```

> **ChatGPT vs Codex:** Store ChatGPT is a single OpenAI desktop app (`OpenAI.Codex_*`) that already includes the Codex agent. Only **Codex CLI** is installed separately (`--with-codex-cli`).

Flags from `optional.ini` or CLI (`--with-cursor`, `--with-chatgpt`, `--with-codex-cli`, etc.) enable install/upgrade for the matching row.

### `config/cleanup.ini`

Disk cleanup profile:

```ini
CLEANUP_TIER=developer
LANGUAGE=en            # fallback; primary language is config\project.ini

RUN_CLEANMGR=1
CLEANMGR_SAGESET=65535
CLEAR_RECYCLE_BIN=1
CLEAR_LOOSE_FILES=1
```

Before the first `cleanmgr` run, configure categories once manually:

```cmd
cleanmgr /sageset:65535
```

### `config/cleanup.list`

Cleanup targets. Format: `MIN_TIER|SCOPE|PATH|NAME_KEY`

```
safe|user|AppData\Local\Temp|user_temp
safe|user|AppData\Local\NVIDIA\DXCache|nvidia_dxcache
developer|user|AppData\Local\pip\cache|pip_cache
aggressive|user|.nuget\packages|nuget_packages
```

- `SCOPE`: `user` (per profile under `C:\Users`) or `system` (once)
- `NAME_KEY`: localization key (prefix `target.` in `lib/i18n-data.ps1`)

### `config/secrets.env`

Copy `secrets.env.example` → `secrets.env` and add keys:

```ini
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

> `secrets.env` and `/logs/` are in `.gitignore` — do not commit keys or logs.

## Scheduled run (monthly)

Run **as Administrator** once:

```cmd
register-scheduled-task.cmd
```

Task `DevWorkstationMaintenance` runs on the 1st of each month at 09:00.

## Project layout

```
dev-workstation-maintenance/
├── LICENSE                        # MIT
├── VERSION                        # Project SemVer (currently 1.0.0)
├── CHANGELOG.md                   # Keep a Changelog
├── SECURITY.md / SECURITY.ru.md   # Security policy (GitHub Security tab)
├── CONTRIBUTING.md / .ru.md       # Contribution guide
├── README.md                      # English (default)
├── README.ru.md                   # Russian
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/            # bug / feature + config
├── maintain-dev-workstation.cmd   # Main maintenance script
├── clean_disk.cmd                 # Disk cleanup launcher
├── clean_disk.ps1                 # Cleanup orchestrator (PowerShell)
├── install-openclaw.cmd           # Official OpenClaw installer
├── register-scheduled-task.cmd    # Scheduled task registration
├── config/
│   ├── project.ini                # Shared settings (language, version, winget scope)
│   ├── packages.list              # winget packages (base dev stack)
│   ├── optional.ini               # Optional service flags
│   ├── optional-apps.list         # Optional AI IDE / desktop apps
│   ├── cleanup.ini                # Disk cleanup profile
│   ├── cleanup.list               # Cleanup targets (tier / scope / path)
│   └── secrets.env.example        # Secrets template
├── lib/
│   ├── i18n.ps1                   # Localization core (PowerShell)
│   ├── i18n-data.ps1              # ru / en strings
│   ├── i18n-export.ps1            # Export I18N_* for CMD (+ apply script)
│   ├── i18n.cmd                   # CMD localization loader
│   ├── optional-apps.cmd          # Cursor, Antigravity, Claude, ChatGPT, Codex CLI, Perplexity
│   ├── optional-ai.cmd            # OpenClaw / OpenRouter
│   ├── cleanup-common.ps1         # Shared cleanup helpers
│   ├── cleanup-user.ps1           # Per-user profile cleanup
│   ├── cleanup-system.ps1         # cleanmgr, Recycle Bin, system paths
│   └── cleanup-i18n.ps1           # Compatibility wrapper → i18n.ps1
└── logs/                          # Logs (gitignored: /logs/)
```

## OpenRouter and Claude Code

When configuring OpenRouter, the script writes to the user environment:

- `OPENROUTER_API_KEY`
- `ANTHROPIC_BASE_URL=https://openrouter.ai/api`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_API_KEY=` (empty string — important for Claude Code)

**Restart the terminal** after install.

## Security

- Reporting and supported versions: [SECURITY.md](SECURITY.md) / [SECURITY.ru.md](SECURITY.ru.md).
- API keys passed via CLI args and internal variables use delayed expansion, reducing command-injection risk with special characters in the key.
- Store API keys in `config/secrets.env` (template: `secrets.env.example`) or pass via `--openrouter-key`.
- `secrets.env` and `/logs/` are in `.gitignore` and are not published.
- The script does not log API key values to `logs/` (including suppressing `reg add` output when writing user env).
- UAC for MSI installers and all-profile cleanup is normal Windows behavior.
- Disk cleanup `-DryRun` only shows a plan; it does not delete files.

## License

This project is released under the **[MIT](LICENSE)** license (SPDX: `MIT`).

Copyright (c) 2026 [Sergey Bezpalov](https://github.com/sbezpalov)

You may freely use, copy, modify, distribute, and sell copies provided the copyright notice and license text are retained. Software is provided “as is”, without warranty.

Full text: [LICENSE](LICENSE) in the repository root.

## Author

[Sergey Bezpalov](https://github.com/sbezpalov)
