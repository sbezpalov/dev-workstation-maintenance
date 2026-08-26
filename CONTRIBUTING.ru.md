# Участие в проекте

[English](CONTRIBUTING.md) · **Русский**

Спасибо за вклад в **Dev Workstation Maintenance**.

## Перед стартом

1. Прочитайте [README.ru.md](README.ru.md) и [SECURITY.ru.md](SECURITY.ru.md)
2. Проверьте существующие issue / PR
3. Вопросы безопасности — только по [SECURITY.ru.md](SECURITY.ru.md), **без** публичного issue

## Окружение

```cmd
git clone https://github.com/sbezpalov/dev-workstation-maintenance.git
cd dev-workstation-maintenance
copy config\secrets.env.example config\secrets.env
```

- Windows 11 (или Windows 10 с App Installer / `winget`)
- Не коммитьте `config/secrets.env` и содержимое `logs/`
- Для тестов предпочитайте `--dry-run` / `-DryRun`
- Перед отправкой изменений запустите `pwsh -NoProfile -File .\tests\validate.ps1`

## Как помочь

### Баги

В issue укажите:

- Сборку ОС и запуск с повышенными правами (да/нет)
- Точную командную строку
- Фрагмент лога из `logs/` **без секретов**

### Фичи

Опишите проблему, предлагаемый флаг/конфиг и соответствие модели `cmd` + `winget` + опциональный PowerShell.

### Pull request

1. Ветка от default branch
2. Узкий scope (одна задача на PR)
3. Обновляйте документацию при смене поведения (`README.md`, `README.ru.md`, строки в `lib/i18n-data.ps1`)
4. Для пользовательских изменений — bump `VERSION` + `VERSION` в `config/project.ini` и запись в [CHANGELOG.md](CHANGELOG.md)
5. Заполните PR template

## Правила кода

- Стиль репозитория: читаемый `cmd` / PowerShell, понятные логи
- Пользовательские строки — через i18n (`lib/i18n-data.ps1`) для `ru` и `en`
- Опциональные AI-приложения — в `config/optional-apps.list` + флаги в `maintain-dev-workstation.cmd` / `config/optional.ini`
- Не логируйте секреты. Редирект команд, печатающих ключи, в `logs/` — баг
- Без телеметрии и phone-home

## Коммиты

Коротко, в императиве, с упором на **зачем**.

## Лицензия

Внося вклад, вы соглашаетесь с лицензией [MIT](LICENSE).
