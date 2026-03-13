# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do not open a public issue.** Instead, please email the maintainer or use [GitHub's private vulnerability reporting](../../security/advisories/new).

We will acknowledge your report within 48 hours and aim to provide a fix within 7 days for critical issues.

## Scope

This plugin executes shell scripts and downloads files from `download.eclipse.org`. Security concerns may include:

- **Download integrity** — The launcher scripts download JDTLS over HTTPS from Eclipse's official servers.
- **Script execution** — The launcher scripts execute Java with specific arguments. Review `bin/launch-jdtls` and `bin/launch-jdtls.ps1` before use.
- **PATH resolution** — The scripts resolve `java` from `JAVA_HOME` or `PATH`. Ensure these are not compromised.
