# Contributing to Java LSP (Eclipse JDT LS)

Thank you for your interest in contributing! Here's how you can help.

## Reporting Issues

- Use [GitHub Issues](../../issues) to report bugs or request features.
- Include your OS, Java version, and Copilot CLI version.
- For LSP errors, include the output of `/lsp` from Copilot CLI.

## Submitting Changes

1. Fork the repository.
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes and test them locally.
4. Commit with a clear message: `git commit -m "Add feature X"`
5. Push and open a Pull Request.

## Testing Locally

Install the plugin from your local directory:

```bash
copilot plugin install ./java-lsp-eclipse-jdt-ls
```

Verify with `/lsp` in Copilot CLI, then test against a Java project.

## Code Style

- Shell scripts: use `shellcheck` for linting.
- Keep scripts POSIX-compatible where possible (`bash` for the launcher is fine).
- PowerShell scripts: follow [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) conventions.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
