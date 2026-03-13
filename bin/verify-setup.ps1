# Verify that the environment is ready for the Java LSP plugin.
# Run this after installing the plugin to pre-check prerequisites
# and pre-download Eclipse JDTLS before first use.
#
# Usage: powershell -ExecutionPolicy Bypass -File bin\verify-setup.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$ScriptDir\lib\common.ps1"

$Pass = [char]0x2713  # ✓
$Fail = [char]0x2717  # ✗
$Errors = 0

Write-Host "Verifying Java LSP (Eclipse JDT LS) setup..."
Write-Host ""

# --- Check Java ---
$Java = Resolve-Java
if (-not $Java) {
    if ($script:JavaVersion -and $script:JavaVersion -gt 0) {
        Write-Host "$Fail Java 21+ is required, but found Java $($script:JavaVersion)." -ForegroundColor Red
    } else {
        Write-Host "$Fail Java not found. Install Java 21+ and set JAVA_HOME or add java to PATH." -ForegroundColor Red
        Write-Host "  Download from: https://adoptium.net/"
    }
    $Errors++
} else {
    Write-Host "$Pass Java $($script:JavaVersion) found ($Java)" -ForegroundColor Green
}

# --- Check JDTLS ---
$JdtlsHome = Find-Jdtls
if ($JdtlsHome) {
    Write-Host "$Pass Eclipse JDTLS found ($JdtlsHome)" -ForegroundColor Green
} else {
    Write-Host "  Eclipse JDTLS not found. Attempting auto-download..."
    $JdtlsHome = Install-Jdtls
    if ($JdtlsHome) {
        Write-Host "$Pass Eclipse JDTLS installed to $JdtlsHome" -ForegroundColor Green
    } else {
        Write-Host "$Fail Eclipse JDTLS download failed. Install manually:" -ForegroundColor Red
        Write-Host "    Download from: https://download.eclipse.org/jdtls/milestones/"
        Write-Host "    Extract and set: JDTLS_HOME=C:\path\to\jdtls"
        $Errors++
    }
}

# --- Verify Equinox launcher JAR ---
if ($JdtlsHome) {
    $LauncherJar = Find-LauncherJar -JdtlsHome $JdtlsHome
    if ($LauncherJar) {
        Write-Host "$Pass Equinox launcher JAR found" -ForegroundColor Green
    } else {
        Write-Host "$Fail Equinox launcher JAR not found in $JdtlsHome\plugins\" -ForegroundColor Red
        $Errors++
    }

    $ConfigDir = Get-ConfigDir -JdtlsHome $JdtlsHome
    if ($ConfigDir) {
        Write-Host "$Pass Platform config directory found ($ConfigDir)" -ForegroundColor Green
    } else {
        Write-Host "$Fail Platform config directory not found: $JdtlsHome\config_win" -ForegroundColor Red
        $Errors++
    }
}

# --- Summary ---
Write-Host ""
if ($Errors -eq 0) {
    Write-Host "All checks passed. The Java LSP plugin is ready to use." -ForegroundColor Green
} else {
    Write-Host "$Errors check(s) failed. Fix the issues above and re-run this script." -ForegroundColor Red
    exit 1
}
