# Dev Workstation Maintenance

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md) · **Русский**

Автоматическое обслуживание рабочего места разработчика на **Windows 11**.

Документы сообщества: [CONTRIBUTING](CONTRIBUTING.ru.md) · [SECURITY](SECURITY.ru.md) · [CHANGELOG](CHANGELOG.md)

Скрипт обновляет инструменты через `winget`, поддерживает **Python/pip** и **npm**-экосистемы, опционально устанавливает **OpenClaw** и настраивает **OpenRouter**, очищает диск от кэшей и временных файлов. Основной сценарий обслуживания работает на **cmd.exe**; модуль очистки диска использует **PowerShell 5+** (встроен в Windows).

Python нужен для IDE и AI-инструментов (Cursor, Antigravity, Claude Code, ChatGPT desktop, Codex CLI, Perplexity, MCP-серверы, расширения VS Code). Детект учитывает **Python Install Manager** (`py`) и игнорирует Store-заглушку в `WindowsApps`.

Интерфейс скриптов локализован: **английский** (по умолчанию) и **русский** (`en` / `ru`). Опция `auto` следует языку интерфейса Windows.

Текущая версия проекта: **1.0.0** (файл [`VERSION`](VERSION), также `VERSION` в `config/project.ini`).

Лицензия: **MIT** — см. [LICENSE](LICENSE).

## Возможности

### Обслуживание (`maintain-dev-workstation.cmd`)

- Последовательная обработка пакетов через `winget` (без блокировки MSI)
- По умолчанию установка **на компьютер** (`--scope machine`, все пользователи); см. `WINGET_SCOPE` в `config/project.ini`
- Три режима в `packages.list`: `upgrade` / `install` / `ensure` (внешние установки Python/PHP не дублируются)
- Обновление pip и устаревших pip-пакетов + `pip check` (через `py -3` или реальный `python`)
- Обновление npm и глобальных npm-пакетов + `npm doctor`
- Health-check: Python, pip, Node, npm, Git, Go, PHP, PowerShell, gh, VS Code, OpenClaw
- Опционально: AI-приложения через winget (Cursor, Antigravity, Claude, ChatGPT, Codex CLI, Perplexity и IDE/CLI варианты)
- Опционально: OpenClaw (официальный `install.ps1` или npm)
- Опционально: OpenRouter (API-ключ, env vars, CLI)
- Журналы в `/logs/` (каталог в `.gitignore`, в публичный репозиторий не попадает)
- Ежемесячный запуск через `schtasks`

### Очистка диска (`clean_disk.cmd` / `clean_disk.ps1`)

- Модульная очистка системного диска для **всех профилей** в `C:\Users\*`
- Три уровня: `safe` → `developer` → `aggressive` (каждый включает предыдущий)
- Кэши GPU: NVIDIA (DXCache, GLCache), AMD (DxCache, DxcCache, VkCache, GLCache, OglpCache), Windows D3DSCache
- Кэши dev-инструментов: pip, npm, Go, Cursor, VS Code, WinGet, NuGet, Gradle, Cargo, pnpm, Yarn
- Опционально: Windows Disk Cleanup (`cleanmgr`), очистка корзины
- Режим `-DryRun`, журнал в `logs/`
- Запрос прав администратора (UAC) для очистки всех профилей

### Локализация (i18n)

- Языки: `en` (по умолчанию), `ru`, `auto` (язык интерфейса Windows)
- Настройка по умолчанию: `LANGUAGE=en` в `config/project.ini`
- Переопределение из CLI: `--language en|ru|auto` (CMD) или `-Language en|ru|auto` (PowerShell)
- Локализованы все пользовательские сообщения: обслуживание, OpenClaw, OpenRouter, optional apps, очистка диска, планировщик

## Требования

- Windows 11 (или Windows 10 с [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1))
- `winget` в PATH
- Для `WINGET_SCOPE=machine` (по умолчанию): запуск **от имени администратора** — иначе часть пакетов уйдёт в fallback без `--scope`
- Для pip-блока: Python через `py` (Install Manager) или реальный `python` в PATH (не Store-заглушка); при отсутствии — `ensure` поставит `Python.Python.3.14`
- Для npm-блока: Node.js
- Для OpenClaw installer и очистки диска: PowerShell 5+ (встроен в Windows)
- Для очистки всех профилей: права администратора

## Быстрый старт

```cmd
git clone https://github.com/sbezpalov/dev-workstation-maintenance.git
cd dev-workstation-maintenance

:: Просмотр без изменений
maintain-dev-workstation.cmd --dry-run

:: Полное обслуживание
maintain-dev-workstation.cmd

:: Очистка диска (dry-run, уровень из config\cleanup.ini)
clean_disk.cmd -DryRun
```

## Использование

### Обслуживание

```cmd
maintain-dev-workstation.cmd [options]
```

| Флаг | Описание |
|------|----------|
| `--dry-run` | Показать план без изменений |
| `--skip-winget` | Пропустить обновления winget |
| `--skip-pip` | Пропустить pip upgrade / check |
| `--skip-npm` | Пропустить npm update / doctor |
| `--with-cursor` | Установить / обновить Cursor IDE |
| `--with-antigravity` | Установить / обновить Antigravity IDE |
| `--with-antigravity-cli` | Установить / обновить Antigravity CLI |
| `--with-claude` | Установить / обновить Claude (desktop) |
| `--with-claude-code` | Установить / обновить Claude Code CLI |
| `--with-chatgpt` | Установить / обновить ChatGPT desktop (Microsoft Store; внутри уже есть Codex) |
| `--with-codex-cli` | Установить / обновить Codex CLI (отдельный терминальный агент) |
| `--with-perplexity` | Установить / обновить Perplexity |
| `--with-perplexity-comet` | Установить / обновить Perplexity Comet |
| `--with-ai-apps` | Все опциональные AI-приложения выше |
| `--with-openclaw` | Установить OpenClaw |
| `--openclaw-onboard` | Полная установка OpenClaw с onboarding |
| `--openclaw-npm` | OpenClaw через npm вместо install.ps1 |
| `--with-openrouter` | Настроить OpenRouter + CLI |
| `--openrouter-key KEY` | API-ключ OpenRouter (`sk-or-v1-...`) |
| `--language en\|ru\|auto` | Язык интерфейса (по умолчанию: `en`) |
| `--scope machine\|user\|auto` | Область winget: на компьютер / на пользователя / как решит winget (по умолчанию: `machine`) |
| `--help` | Справка |

### Очистка диска

```cmd
clean_disk.cmd [options]
```

| Параметр | Описание |
|----------|----------|
| `-DryRun` | Показать план без удаления |
| `-Tier safe\|developer\|aggressive` | Уровень очистки (переопределяет `config\cleanup.ini`) |
| `-Language en\|ru\|auto` | Язык интерфейса |
| `--language en\|ru\|auto` | То же (для CMD-лаунчера) |
| `--pause` | Оставить окно CMD открытым после завершения очистки |

Уровни очистки:

| Уровень | Что удаляется |
|---------|---------------|
| `safe` | Temp, кэши шейдеров GPU (NVIDIA / AMD / Windows), `*.tmp` / `*.dmp` в корне профиля |
| `developer` | + кэши pip, npm, Go, IDE (Cursor, VS Code), WinGet, Internet / Web cache |
| `aggressive` | + NuGet, Gradle, Cargo, pnpm, Yarn (перекачка при следующем использовании) |

### OpenClaw

```cmd
install-openclaw.cmd [--quick|--no-onboard] [--language en|ru|auto]
```

| Флаг | Описание |
|------|----------|
| `--quick` | Установка без интерактивного onboarding |
| `--no-onboard` | Псевдоним для `--quick` |
| `--language en\|ru\|auto` | Язык сообщений |
| `--help` | Показать справку без установки |

### Примеры

```cmd
:: Только dev-инструменты
maintain-dev-workstation.cmd

:: С русским интерфейсом
maintain-dev-workstation.cmd --language ru --dry-run

:: AI IDE и desktop-приложения (без OpenClaw)
maintain-dev-workstation.cmd --with-cursor --with-claude-code --with-perplexity

:: Все AI-приложения из optional-apps.list
maintain-dev-workstation.cmd --with-ai-apps

:: OpenClaw + OpenRouter
maintain-dev-workstation.cmd --with-openclaw --with-openrouter --openrouter-key sk-or-v1-XXX

:: Официальный установщик OpenClaw отдельно
install-openclaw.cmd
install-openclaw.cmd --quick

:: Очистка диска: агрессивный уровень, dry-run
clean_disk.cmd -DryRun -Tier aggressive

:: Очистка с русским интерфейсом
clean_disk.cmd --language ru -DryRun
```

## Конфигурация

### `config/project.ini`

Общие настройки проекта:

```ini
# UI language: en | ru | auto  (default: en)
LANGUAGE=en

# SemVer (also in root VERSION file)
VERSION=1.0.0

# winget: machine | user | auto
# machine = на компьютер / всех пользователей (по умолчанию; обычно нужен Administrator)
WINGET_SCOPE=machine
```

### `config/packages.list`

Список пакетов winget. Формат: `ACTION|WINGET_ID|DISPLAY_NAME[|PROBE]`

Текущий базовый стек:

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

| ACTION | Поведение |
|--------|-----------|
| `upgrade` | `winget upgrade` (пакет ожидается из winget) |
| `install` | `winget install` (если ещё нет) |
| `ensure` | если `PROBE` есть в PATH и реально работает — пропуск (внешнее управление); иначе `winget install` |

**Зачем `ensure`:** Python часто стоит через **Python Install Manager** (`py`), PHP — вручную (`C:\Program Files\PHP\...`). Скрипт не ставит второй экземпляр рядом с рабочей установкой.

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

Список AI desktop / IDE приложений для winget. Формат: `FLAG|WINGET_ID|DISPLAY_NAME|CLI_TOOL|CLI_CMD`

```
INSTALL_CURSOR|Anysphere.Cursor|Cursor|cursor|cursor --version
INSTALL_CLAUDE_CODE|Anthropic.ClaudeCode|Claude Code|claude|claude --version
INSTALL_CHATGPT|9PLM9XGG6VKS|ChatGPT (incl. Codex)||
INSTALL_CODEX_CLI|OpenAI.Codex|Codex CLI|codex|codex --version
```

> **ChatGPT vs Codex:** desktop ChatGPT из Store — единое приложение OpenAI (`OpenAI.Codex_*`), в нём уже есть агент Codex. Отдельно ставится только **Codex CLI** (`--with-codex-cli`).

Флаги из `optional.ini` или CLI (`--with-cursor`, `--with-chatgpt`, `--with-codex-cli` и т.д.) включают установку / обновление соответствующей строки.

### `config/cleanup.ini`

Профиль очистки диска:

```ini
CLEANUP_TIER=developer
LANGUAGE=en            # fallback; основной язык — config\project.ini

RUN_CLEANMGR=1
CLEANMGR_SAGESET=65535
CLEAR_RECYCLE_BIN=1
CLEAR_LOOSE_FILES=1
```

Перед первым запуском `cleanmgr` выполните один раз вручную:

```cmd
cleanmgr /sageset:65535
```

### `config/cleanup.list`

Цели очистки. Формат: `MIN_TIER|SCOPE|PATH|NAME_KEY`

```
safe|user|AppData\Local\Temp|user_temp
safe|user|AppData\Local\NVIDIA\DXCache|nvidia_dxcache
developer|user|AppData\Local\pip\cache|pip_cache
aggressive|user|.nuget\packages|nuget_packages
```

- `SCOPE`: `user` (для каждого профиля в `C:\Users`) или `system` (один раз)
- `NAME_KEY`: ключ локализации (префикс `target.` в `lib/i18n-data.ps1`)

### `config/secrets.env`

Скопируйте `secrets.env.example` → `secrets.env` и добавьте ключи:

```ini
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

> `secrets.env` и `/logs/` в `.gitignore` — не коммитьте ключи и журналы.

## Автозапуск (ежемесячно)

Запустите **от имени администратора** один раз:

```cmd
register-scheduled-task.cmd
```

Задача `DevWorkstationMaintenance` выполняется 1-го числа каждого месяца в 09:00.

## Структура проекта

```
dev-workstation-maintenance/
├── LICENSE                        # MIT
├── VERSION                        # SemVer проекта (сейчас 1.0.0)
├── CHANGELOG.md                   # История изменений (Keep a Changelog)
├── SECURITY.md / SECURITY.ru.md   # Политика безопасности (вкладка Security)
├── CONTRIBUTING.md / .ru.md       # Как участвовать в проекте
├── README.md                      # English (по умолчанию)
├── README.ru.md                   # Русский
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/            # bug / feature + config
├── maintain-dev-workstation.cmd   # Главный скрипт обслуживания
├── clean_disk.cmd                 # Лаунчер очистки диска
├── clean_disk.ps1                 # Оркестратор очистки (PowerShell)
├── install-openclaw.cmd           # Официальный установщик OpenClaw
├── register-scheduled-task.cmd    # Регистрация задачи в планировщике
├── config/
│   ├── project.ini                # Общие настройки (язык, версия, winget scope)
│   ├── packages.list              # Пакеты winget (базовый dev-стек)
│   ├── optional.ini               # Флаги опциональных сервисов
│   ├── optional-apps.list         # Опциональные AI IDE / desktop apps
│   ├── cleanup.ini                # Профиль очистки диска
│   ├── cleanup.list               # Цели очистки (tier / scope / path)
│   └── secrets.env.example        # Шаблон секретов
├── lib/
│   ├── i18n.ps1                   # Ядро локализации (PowerShell)
│   ├── i18n-data.ps1              # Строки ru / en
│   ├── i18n-export.ps1            # Экспорт I18N_* для CMD (+ apply-скрипт)
│   ├── i18n.cmd                   # Загрузчик локализации для CMD
│   ├── optional-apps.cmd          # Cursor, Antigravity, Claude, ChatGPT, Codex CLI, Perplexity
│   ├── optional-ai.cmd            # OpenClaw / OpenRouter
│   ├── cleanup-common.ps1         # Общие функции очистки
│   ├── cleanup-user.ps1           # Очистка профилей пользователей
│   ├── cleanup-system.ps1         # cleanmgr, корзина, системные пути
│   └── cleanup-i18n.ps1           # Обёртка совместимости → i18n.ps1
└── logs/                          # Журналы (игнорируется git: /logs/)
```

## OpenRouter и Claude Code

При настройке OpenRouter скрипт сохраняет в пользовательское окружение:

- `OPENROUTER_API_KEY`
- `ANTHROPIC_BASE_URL=https://openrouter.ai/api`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_API_KEY=` (пустая строка — важно для Claude Code)

После установки **перезапустите терминал**.

## Проверка проекта

Запустите проверки через встроенный Windows PowerShell 5.1 или PowerShell 7:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\validate.ps1
pwsh -NoProfile -File .\tests\validate.ps1
```

Проверяются синтаксис PowerShell, паритет локализации, схемы конфигурации, дубликаты package ID, ограничения путей очистки, согласованность версии и справка CMD. GitHub Actions выполняет те же проверки на Windows.

## Безопасность

- Подробности и ответственное раскрытие: [SECURITY.ru.md](SECURITY.ru.md) / [SECURITY.md](SECURITY.md).
- Для API-ключей предпочтителен `config/secrets.env` (шаблон — `secrets.env.example`). Опция `--openrouter-key` удобна, но ключ может остаться в истории оболочки и быть виден при инспекции процессов.
- `secrets.env` и `/logs/` в `.gitignore` — не попадают в публичный репозиторий.
- Скрипт не логирует значения API-ключей в `logs/` (в т.ч. вывод `reg add` при записи user env подавляется).
- UAC для MSI-инсталляторов и фактической очистки всех профилей — штатное поведение Windows.
- `-DryRun` у очистки диска только показывает план, не удаляет файлы и не запрашивает UAC.
- Пути очистки ограничены соответствующим профилем пользователя или `%SystemRoot%`; ссылки и reparse points пропускаются.

## Лицензия

Проект распространяется под лицензией **[MIT](LICENSE)** (SPDX: `MIT`).

Copyright (c) 2026 [Sergey Bezpalov](https://github.com/sbezpalov)

Разрешено свободно использовать, копировать, изменять, распространять и продавать копии при сохранении текста copyright и самого текста лицензии. ПО предоставляется «как есть», без гарантий.

Полный текст: файл [LICENSE](LICENSE) в корне репозитория.

## Автор

[Sergey Bezpalov](https://github.com/sbezpalov)
