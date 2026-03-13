# Java LSP (Eclipse JDT LS) — Plugin for GitHub Copilot CLI

A [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-getting-started) plugin that configures [Eclipse JDT Language Server](https://github.com/eclipse-jdtls/eclipse.jdt.ls) as the Java language server, providing code intelligence for `.java` files.

## What It Provides

- **LSP configuration** for Eclipse JDT LS — auto-registered for all `.java` files
- **Cross-platform launcher scripts** for macOS, Linux, and Windows
- **Setup skill** — Copilot can guide you through Eclipse JDT LS installation and troubleshooting

## Prerequisites

- **Java 21+** — [Download from Adoptium](https://adoptium.net/) or use your preferred distribution

Eclipse JDT LS itself is **downloaded automatically** by the launcher scripts on first use. No manual installation required.

## Installing the Plugin

```bash
copilot plugin install ./java-lsp-eclipse-jdt-ls
```

Or from a GitHub repository:

```bash
copilot plugin install jdubois/java-lsp-eclipse-jdt-ls
```

## Installing Eclipse JDT LS

Eclipse JDT LS is **automatically downloaded** when the plugin's launcher script runs for the first time and is not already present on the system.

| Platform | Auto-install location | Requires |
|----------|----------------------|----------|
| macOS / Linux | `~/.local/share/jdtls` | `curl`, `tar` |
| Windows | `%LOCALAPPDATA%\jdtls` | PowerShell 5+ (built-in) |

If auto-download fails (no internet, firewall), you can install manually:

### macOS

```bash
brew install jdtls
```

### macOS / Linux (Manual)

1. Download from https://download.eclipse.org/jdtls/milestones/
2. Extract to `~/.local/share/jdtls`
3. Optionally: `export JDTLS_HOME=~/.local/share/jdtls`

### Windows (Manual)

1. Download from https://download.eclipse.org/jdtls/milestones/
2. Extract to `%LOCALAPPDATA%\jdtls`
3. Optionally set: `JDTLS_HOME=%LOCALAPPDATA%\jdtls`

## How It Works

The plugin registers Eclipse JDT LS as an LSP server via `lsp.json`. When Copilot CLI opens a `.java` file, it starts the language server and uses the Language Server Protocol for code intelligence — go-to-definition, hover, completions, diagnostics, and more.

### LSP Configuration

The plugin ships with this default LSP configuration (`lsp.json`):

```json
{
  "java-lsp-eclipse-jdt-ls": {
    "command": "./bin/launch-jdtls",
    "args": [],
    "fileExtensions": {
      ".java": "java-lsp-eclipse-jdt-ls"
    }
  }
}
```

The `command` path is resolved relative to the plugin's installed directory — no Python wrapper or PATH configuration needed. The bundled bash script auto-detects your OS (macOS or Linux) and finds JDTLS automatically.

### Platform-Specific Launcher Scripts

| Platform | Script | Notes |
|----------|--------|-------|
| macOS / Linux | `bin/launch-jdtls` | **Default.** Bash script, auto-detects OS and JDTLS location |
| Windows | `bin/launch-jdtls.ps1` | Requires manual override (see below) |

### Windows Setup

On Windows, override the LSP config in `~/.copilot/lsp-config.json` to use the PowerShell launcher:

```json
{
  "lspServers": {
    "java-lsp-eclipse-jdt-ls": {
      "command": "powershell",
      "args": ["-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOU\\.copilot\\state\\installed-plugins\\java-lsp-eclipse-jdt-ls\\bin\\launch-jdtls.ps1"],
      "fileExtensions": {
        ".java": "java-lsp-eclipse-jdt-ls"
      }
    }
  }
}
```

Replace `YOU` with your Windows username. This user-level config takes precedence over the plugin's default.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JAVA_HOME` | Path to JDK installation | Auto-detected from PATH |
| `JDTLS_HOME` | Path to Eclipse JDT LS installation directory | Auto-detected from common locations |
| `JDTLS_DATA_DIR` | Workspace data directory | `~/.cache/jdtls-workspace` |

## Verifying Setup

1. Start Copilot CLI with experimental mode: `copilot --experimental`
2. Navigate to a Java project directory
3. Use the `/lsp` command to check the server status
4. Open a `.java` file — Copilot should now have enhanced code intelligence

## Troubleshooting

Use the built-in skill for help:

```
Use the /eclipse-jdtls-setup skill to troubleshoot my Java language server
```

Or see the full troubleshooting guide in `skills/eclipse-jdtls-setup/SKILL.md`.

## License

[MIT](LICENSE)
