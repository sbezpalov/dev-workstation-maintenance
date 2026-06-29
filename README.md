# Dev Workstation Maintenance

Автоматическое обслуживание рабочего места разработчика на **Windows 11**.

Скрипт обновляет инструменты через `winget`, поддерживает **Python/pip** и **npm**-экосистемы, опционально устанавливает **OpenClaw** и настраивает **OpenRouter**. Работает на чистом **cmd.exe** — без обязательной зависимости от PowerShell.

Python нужен для IDE и AI-инструментов (Cursor, Antigravity, Claude Code, Perplexity, MCP-серверы, расширения VS Code).

## Возможности

- Последовательное обновление пакетов через `winget` (без блокировки MSI)
- Обновление Python 3.13 + Python Launcher через `winget`
- Обновление pip и устаревших pip-пакетов + `pip check`
- Обновление npm и глобальных npm-пакетов + `npm doctor`
- Health-check версий: Python, pip, py launcher, Node, npm, Git, Go, PHP, PowerShell, gh, VS Code
- Опционально: AI-приложения через winget (Cursor, Antigravity, Claude, Perplexity и их IDE/CLI варианты)
- Опционально: OpenClaw (официальный `install.ps1` или npm)
- Опционально: OpenRouter (API-ключ, env vars, CLI)
- Журналы в `logs/`
- Ежемесячный запуск через `schtasks`

## Требования

- Windows 11 (или Windows 10 с [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1))
- `winget` в PATH
- Для pip-блока: Python (ставится через `winget`, если ещё нет)
- Для npm-блока: Node.js
- Для OpenClaw installer: PowerShell 5+ (встроен в Windows)

## Быстрый старт

```cmd
git clone https://github.com/sbezpalov/dev-workstation-maintenance.git
cd dev-workstation-maintenance

:: Просмотр без изменений
maintain-dev-workstation.cmd --dry-run

:: Полное обслуживание
maintain-dev-workstation.cmd
```

## Использование

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
| `--with-perplexity` | Установить / обновить Perplexity |
| `--with-perplexity-comet` | Установить / обновить Perplexity Comet |
| `--with-ai-apps` | Все опциональные AI-приложения выше |
| `--with-openclaw` | Установить OpenClaw |
| `--openclaw-onboard` | Полная установка OpenClaw с onboarding |
| `--openclaw-npm` | OpenClaw через npm вместо install.ps1 |
| `--with-openrouter` | Настроить OpenRouter + CLI |
| `--openrouter-key KEY` | API-ключ OpenRouter (`sk-or-v1-...`) |
| `--help` | Справка |

### Примеры

```cmd
:: Только dev-инструменты
maintain-dev-workstation.cmd

:: AI IDE и desktop-приложения (без OpenClaw)
maintain-dev-workstation.cmd --with-cursor --with-claude-code --with-perplexity

:: Все AI-приложения из optional-apps.list
maintain-dev-workstation.cmd --with-ai-apps

:: OpenClaw + OpenRouter
maintain-dev-workstation.cmd --with-openclaw --with-openrouter --openrouter-key sk-or-v1-XXX

:: Официальный установщик OpenClaw отдельно
install-openclaw.cmd
install-openclaw.cmd --quick
```

## Конфигурация

### `config/packages.list`

Список пакетов winget. Формат: `ACTION|WINGET_ID|DISPLAY_NAME`

```
upgrade|OpenJS.NodeJS.LTS|Node.js LTS
upgrade|Git.Git|Git
install|GitHub.cli|GitHub CLI
```

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
INSTALL_PERPLEXITY=0
INSTALL_PERPLEXITY_COMET=0
```

### `config/optional-apps.list`

Список AI desktop / IDE приложений для winget. Формат: `FLAG|WINGET_ID|DISPLAY_NAME|CLI_TOOL|CLI_CMD`

```
INSTALL_CURSOR|Anysphere.Cursor|Cursor|cursor|cursor --version
INSTALL_CLAUDE_CODE|Anthropic.ClaudeCode|Claude Code|claude|claude --version
```

Флаги из `optional.ini` или CLI (`--with-cursor` и т.д.) включают установку / обновление соответствующей строки.

### `config/secrets.env`

Скопируйте `secrets.env.example` → `secrets.env` и добавьте ключи:

```ini
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

> `secrets.env` в `.gitignore` — не коммитьте ключи.

## Автозапуск (ежемесячно)

Запустите **от имени администратора** один раз:

```cmd
register-scheduled-task.cmd
```

Задача `DevWorkstationMaintenance` выполняется 1-го числа каждого месяца в 09:00.

## Структура проекта

```
dev-workstation-maintenance/
├── maintain-dev-workstation.cmd   # Главный скрипт
├── install-openclaw.cmd           # Официальный установщик OpenClaw
├── register-scheduled-task.cmd    # Регистрация задачи в планировщике
├── config/
│   ├── packages.list              # Пакеты winget (базовый dev-стек)
│   ├── optional-apps.list         # Опциональные AI IDE / desktop apps
│   ├── optional.ini               # Флаги опциональных сервисов
│   └── secrets.env.example        # Шаблон секретов
├── lib/
│   ├── optional-apps.cmd          # Cursor, Antigravity, Claude, Perplexity
│   └── optional-ai.cmd            # OpenClaw / OpenRouter
└── logs/                          # Журналы (не в git)
```

## OpenRouter и Claude Code

При настройке OpenRouter скрипт сохраняет в пользовательское окружение:

- `OPENROUTER_API_KEY`
- `ANTHROPIC_BASE_URL=https://openrouter.ai/api`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_API_KEY=` (пустая строка — важно для Claude Code)

После установки **перезапустите терминал**.

## Безопасность

- API-ключи храните только в `config/secrets.env` или передавайте через флаг
- Не коммитьте `secrets.env`
- UAC-запросы для MSI-пакетов — нормальное поведение Windows

## Лицензия

[MIT](LICENSE) — свободное использование, модификация и распространение.

## Автор

[Sergey Bezpalov](https://github.com/sbezpalov)
