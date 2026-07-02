# Dev Workstation Maintenance

Автоматическое обслуживание рабочего места разработчика на **Windows 11**.

Скрипт обновляет инструменты через `winget`, поддерживает **Python/pip** и **npm**-экосистемы, опционально устанавливает **OpenClaw** и настраивает **OpenRouter**, очищает диск от кэшей и временных файлов. Основной сценарий обслуживания работает на **cmd.exe**; модуль очистки диска использует **PowerShell 5+** (встроен в Windows).

Python нужен для IDE и AI-инструментов (Cursor, Antigravity, Claude Code, Perplexity, MCP-серверы, расширения VS Code).

Интерфейс скриптов локализован: **русский** и **английский** (`ru` / `en`), с автоопределением по языку системы.

## Возможности

### Обслуживание (`maintain-dev-workstation.cmd`)

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

### Очистка диска (`clean_disk.cmd` / `clean_disk.ps1`)

- Модульная очистка системного диска для **всех профилей** в `C:\Users\*`
- Три уровня: `safe` → `developer` → `aggressive` (каждый включает предыдущий)
- Кэши GPU: NVIDIA (DXCache, GLCache), AMD (DxCache, DxcCache, VkCache, GLCache, OglpCache), Windows D3DSCache
- Кэши dev-инструментов: pip, npm, Go, Cursor, VS Code, WinGet, NuGet, Gradle, Cargo, pnpm, Yarn
- Опционально: Windows Disk Cleanup (`cleanmgr`), очистка корзины
- Режим `-DryRun`, журнал в `logs/`
- Запрос прав администратора (UAC) для очистки всех профилей

### Локализация (i18n)

- Языки: `ru`, `en`, `auto` (русский при русской системе, иначе английский)
- Настройка по умолчанию: `config/project.ini`
- Переопределение из CLI: `--language ru|en` (CMD) или `-Language ru|en` (PowerShell)
- Локализованы все пользовательские сообщения: обслуживание, OpenClaw, OpenRouter, optional apps, очистка диска, планировщик

## Требования

- Windows 11 (или Windows 10 с [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1))
- `winget` в PATH
- Для pip-блока: Python (ставится через `winget`, если ещё нет)
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
| `--with-perplexity` | Установить / обновить Perplexity |
| `--with-perplexity-comet` | Установить / обновить Perplexity Comet |
| `--with-ai-apps` | Все опциональные AI-приложения выше |
| `--with-openclaw` | Установить OpenClaw |
| `--openclaw-onboard` | Полная установка OpenClaw с onboarding |
| `--openclaw-npm` | OpenClaw через npm вместо install.ps1 |
| `--with-openrouter` | Настроить OpenRouter + CLI |
| `--openrouter-key KEY` | API-ключ OpenRouter (`sk-or-v1-...`) |
| `--language ru\|en` | Язык интерфейса (по умолчанию: `auto`) |
| `--help` | Справка |

### Очистка диска

```cmd
clean_disk.cmd [options]
```

| Параметр | Описание |
|----------|----------|
| `-DryRun` | Показать план без удаления |
| `-Tier safe\|developer\|aggressive` | Уровень очистки (переопределяет `config\cleanup.ini`) |
| `-Language ru\|en` | Язык интерфейса |
| `--language ru\|en` | То же (для CMD-лаунчера) |

Уровни очистки:

| Уровень | Что удаляется |
|---------|---------------|
| `safe` | Temp, кэши шейдеров GPU (NVIDIA / AMD / Windows), `*.tmp` / `*.dmp` в корне профиля |
| `developer` | + кэши pip, npm, Go, IDE (Cursor, VS Code), WinGet, Internet / Web cache |
| `aggressive` | + NuGet, Gradle, Cargo, pnpm, Yarn (перекачка при следующем использовании) |

### OpenClaw

```cmd
install-openclaw.cmd [--quick] [--language ru|en]
```

| Флаг | Описание |
|------|----------|
| `--quick` | Установка без интерактивного onboarding |
| `--language ru\|en` | Язык сообщений |

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

:: Очистка с английским интерфейсом
clean_disk.cmd --language en -DryRun
```

## Конфигурация

### `config/project.ini`

Общие настройки проекта:

```ini
# UI language: auto | ru | en
LANGUAGE=auto
```

### `config/packages.list`

Список пакетов winget. Формат: `ACTION|WINGET_ID|DISPLAY_NAME`

```
upgrade|OpenJS.NodeJS.LTS|Node.js LTS
upgrade|Python.Python.3.13|Python 3.13
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

### `config/cleanup.ini`

Профиль очистки диска:

```ini
CLEANUP_TIER=developer
LANGUAGE=auto          # fallback; основной язык — config\project.ini

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
├── maintain-dev-workstation.cmd   # Главный скрипт обслуживания
├── clean_disk.cmd                 # Лаунчер очистки диска
├── clean_disk.ps1                 # Оркестратор очистки (PowerShell)
├── install-openclaw.cmd           # Официальный установщик OpenClaw
├── register-scheduled-task.cmd    # Регистрация задачи в планировщике
├── config/
│   ├── project.ini                # Общие настройки (язык)
│   ├── packages.list              # Пакеты winget (базовый dev-стек)
│   ├── optional.ini               # Флаги опциональных сервисов
│   ├── optional-apps.list         # Опциональные AI IDE / desktop apps
│   ├── cleanup.ini                # Профиль очистки диска
│   ├── cleanup.list               # Цели очистки (tier / scope / path)
│   └── secrets.env.example        # Шаблон секретов
├── lib/
│   ├── i18n.ps1                   # Ядро локализации (PowerShell)
│   ├── i18n-data.ps1              # Строки ru / en
│   ├── i18n-export.ps1            # Экспорт I18N_* для CMD
│   ├── i18n.cmd                   # Загрузчик локализации для CMD
│   ├── optional-apps.cmd          # Cursor, Antigravity, Claude, Perplexity
│   ├── optional-ai.cmd            # OpenClaw / OpenRouter
│   ├── cleanup-common.ps1         # Общие функции очистки
│   ├── cleanup-user.ps1           # Очистка профилей пользователей
│   ├── cleanup-system.ps1         # cleanmgr, корзина, системные пути
│   └── cleanup-i18n.ps1           # Обёртка совместимости → i18n.ps1
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

- Передача API-ключей безопасна: аргументы командной строки и внутренние переменные обрабатываются через безопасное отложенное расширение (`delayed expansion`), что предотвращает инъекции команд (Command Injection) при наличии спецсимволов.
- API-ключи рекомендуется хранить в `config/secrets.env` (шаблон в `secrets.env.example`) или безопасно передавать через флаг `--openrouter-key`.
- Файл `secrets.env` добавлен в `.gitignore` и никогда не попадет в репозиторий.
- Скрипт не логирует значения API-ключей в файлы журналов `logs/`.
- UAC-запросы для инсталляторов MSI и очистки всех профилей — стандартное поведение Windows.
- Очистка диска в режиме `-DryRun` не удаляет файлы — только показывает план.

## Лицензия

[MIT](LICENSE) — свободное использование, модификация и распространение.

## Автор

[Sergey Bezpalov](https://github.com/sbezpalov)
