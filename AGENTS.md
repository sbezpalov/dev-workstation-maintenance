# AGENTS.md

## Cursor Cloud specific instructions

This repository (`dev-workstation-maintenance`) is a **Windows-only** developer-workstation
maintenance toolkit built from `.cmd` (batch) and PowerShell (`.ps1`) scripts. There is no
build system, no dependency manifest (no `package.json`/`requirements.txt`/lockfile), and no
automated test suite. See `README.md` and `CONTRIBUTING.md` for the product/usage details.

### What can and cannot run here

The Cloud Agent VM is **Linux (Ubuntu)**. The runtime flows are Windows-only and cannot execute
here, because they depend on `cmd.exe`, `winget`, `schtasks`, `C:\Users\*` paths, and
Windows-only PowerShell APIs (`Get-PSDrive`, `WindowsPrincipal`/`WindowsIdentity`,
`Start-Process -Verb RunAs`). Do **not** expect `maintain-dev-workstation.cmd`,
`clean_disk.cmd`/`clean_disk.ps1`, `install-openclaw.cmd`, or `register-scheduled-task.cmd` to
run on this VM. In particular, the `.ps1` cleanup scripts dot-source their helpers with
backslash paths (e.g. `Join-Path $ScriptDir 'lib\i18n.ps1'`), which do not resolve on Linux.

Only static analysis and the platform-agnostic localization engine run on Linux (see below).
Full runtime verification of the maintenance/cleanup flows requires an actual Windows host.

### Toolchain (installed by the update script)

- **PowerShell Core (`pwsh`)** — used to lint and syntax-check the `.ps1` scripts and to run
  the i18n engine.
- **PSScriptAnalyzer** (PowerShell Gallery module, installed `AllUsers`) — the linter.

### Lint / test / run commands

Run these from the repo root (`/workspace`):

- Lint (all scripts):
  `pwsh -NoProfile -Command "Import-Module PSScriptAnalyzer; Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning"`
  The current tree has 0 errors and ~15 pre-existing style **warnings** (Write-Host usage,
  plural nouns, missing BOM, etc.). Treat only new **errors** as regressions.
- Syntax check (acts as the test suite):
  parse every `*.ps1` with `[System.Management.Automation.Language.Parser]::ParseFile(...)`
  and assert zero parse errors.
- Localization smoke test (genuine core code, cross-platform): dot-source `./lib/i18n.ps1`,
  then call `Get-ProjectLanguagePreference`, `Initialize-ProjectLanguage`, and `L <key> [args]`
  to render localized (`en`/`ru`) strings. This reads `config/project.ini` for the language.

### Gotchas

- Install PowerShell modules with `sudo` (`-Scope AllUsers`); the `ubuntu` user cannot write to
  `/usr/local/share/powershell/Modules` without it.
- PSScriptAnalyzer runs static analysis, so it lints the Windows-only scripts fine even though
  they cannot execute on Linux.
