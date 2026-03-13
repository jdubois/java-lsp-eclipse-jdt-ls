# Copilot Instructions

## Project Overview

This is a **GitHub Copilot CLI plugin** that integrates Eclipse JDT Language Server (JDTLS) as the Java LSP provider. It is not a Java application — it's a plugin consisting of configuration files and cross-platform launcher scripts.

## Architecture

- `plugin.json` — Plugin manifest (name, version, author, references to skills and LSP config)
- `lsp.json` — LSP server registration; maps `.java` files to the `bin/launch-jdtls` launcher
- `bin/launch-jdtls` — Bash launcher (macOS/Linux): resolves Java, finds or auto-downloads JDTLS, launches via stdio
- `bin/launch-jdtls.ps1` — PowerShell launcher (Windows): same logic as the bash script
- `skills/eclipse-jdtls-setup/SKILL.md` — Copilot skill for guided installation and troubleshooting

The launchers follow a consistent flow: resolve Java → verify version ≥ 21 → find JDTLS (env var → known paths) → auto-download if missing → find Equinox launcher JAR → detect platform config dir → exec JDTLS via stdio.

## Linting

- **Shell scripts**: Lint with `shellcheck bin/launch-jdtls`
- **PowerShell scripts**: Follow [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) conventions

## Testing

No automated test suite. Test manually:

```bash
copilot plugin install ./java-lsp-eclipse-jdt-ls
copilot --experimental
# Then use /lsp to verify the server starts, and open a .java file
```

## Code Conventions

- 2-space indentation for all files (`.editorconfig` enforced)
- LF line endings everywhere except `.ps1` and `.cmd` files which use CRLF
- Bash scripts should be POSIX-compatible where possible; `bash` is acceptable for the launchers
- Both launchers must stay in sync — any logic change in one must be mirrored in the other
- Launcher scripts write all user-facing messages to stderr (stdout is reserved for LSP stdio communication)
- JDTLS auto-download location: `~/.local/share/jdtls` (macOS/Linux), `%LOCALAPPDATA%\jdtls` (Windows)

## Environment Variables

- `JAVA_HOME` — JDK path (auto-detected from PATH if unset)
- `JDTLS_HOME` — JDTLS installation directory (auto-detected from known locations if unset)
- `JDTLS_DATA_DIR` — Workspace data directory (defaults to `~/.cache/jdtls-workspace`)
