---
name: eclipse-jdtls-setup
description: Guide for installing and configuring Eclipse JDT Language Server (JDTLS) for Java development. Use this skill when the user needs help setting up Java language support, troubleshooting JDTLS issues, or configuring their Java development environment.
---

# Eclipse JDTLS Setup Guide

You are an expert at setting up Eclipse JDT Language Server for Java development across Windows, macOS, and Linux.

## Prerequisites

- **Java 21 or later** must be installed. Verify with `java -version`.
- Set `JAVA_HOME` to point to your JDK installation.

## Automatic Download

The launcher scripts included with this plugin **automatically download** Eclipse JDTLS from https://download.eclipse.org/jdtls/milestones/ if it is not already installed. The scripts:

1. Check `JDTLS_HOME` and common installation paths
2. If not found, detect the latest milestone version
3. Download and extract to `~/.local/share/jdtls` (macOS/Linux) or `%LOCALAPPDATA%\jdtls` (Windows)
4. Fall back to manual instructions only if the download fails

## Manual Installation (Fallback)

If auto-download fails (e.g., no internet, firewall restrictions), install manually:

### macOS (Homebrew)

```bash
brew install jdtls
```

### macOS / Linux (Manual Download)

1. Download the latest milestone from https://download.eclipse.org/jdtls/milestones/
2. Extract to a directory, for example `~/.local/share/jdtls`
3. Set environment variable: `export JDTLS_HOME=~/.local/share/jdtls`
4. Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.)

### Windows (Manual Download)

1. Download the latest milestone from https://download.eclipse.org/jdtls/milestones/
2. Extract to a directory, for example `%LOCALAPPDATA%\jdtls`
3. Set environment variable: `JDTLS_HOME=%LOCALAPPDATA%\jdtls`

### Linux (Package Manager)

Some distributions provide JDTLS packages:

- **Arch Linux**: `pacman -S jdtls`
- **Other distributions**: Check your package repository for `jdtls` or `eclipse-jdt-ls`

## Verifying the Installation

After installation, verify that the `plugins/` directory exists inside your JDTLS installation and contains `org.eclipse.equinox.launcher_*.jar`.

```bash
ls $JDTLS_HOME/plugins/org.eclipse.equinox.launcher_*.jar
```

## LSP Configuration for Copilot CLI

This plugin automatically configures JDTLS via the bundled `bin/launch-jdtls` bash script (macOS/Linux). The script auto-detects your platform and JDTLS location — no Python wrapper needed.

**Windows users** must override the config in `~/.copilot/lsp-config.json` to use the PowerShell launcher:

```json
{
  "lspServers": {
    "java-lsp-eclipse-jdt-ls": {
      "command": "powershell",
      "args": ["-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOU\\.copilot\\state\\installed-plugins\\java-lsp-eclipse-jdt-ls\\bin\\launch-jdtls.ps1"],
      "fileExtensions": {
        ".java": "java"
      }
    }
  }
}
```

## Troubleshooting

### "Java not found"
- Ensure Java 21+ is installed: `java -version`
- Set `JAVA_HOME` environment variable to your JDK path

### "Eclipse JDTLS not found"
- Set the `JDTLS_HOME` environment variable to the JDTLS installation directory
- Ensure the directory contains a `plugins/` subdirectory with the launcher JAR

### "Configuration directory not found"
- Verify that `config_linux/`, `config_mac/`, or `config_win/` exists in `$JDTLS_HOME`
- Re-download JDTLS if these directories are missing

### No completions or diagnostics
1. Ensure the project root contains `pom.xml` or `build.gradle`
2. For Maven projects, run `mvn dependency:resolve` to populate the local cache
3. For Gradle projects, run `gradle build` once to populate the local cache
4. Check JDTLS logs for errors

### Memory issues
- Increase heap size by setting `JAVA_OPTS=-Xmx2G` before launching
- Large projects may need 2-4 GB of heap space
