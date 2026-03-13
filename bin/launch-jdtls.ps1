# Eclipse JDTLS launcher for Windows (PowerShell)
# This script finds Eclipse JDT Language Server, downloading it automatically
# if not found, then launches it with the correct platform-specific configuration.
# It communicates via stdio for LSP.
#
# Prerequisites:
#   - Java 21+ (set JAVA_HOME or have 'java' on PATH)
#
# Environment variables:
#   JDTLS_HOME       - Path to the JDTLS installation directory
#   JAVA_HOME        - Path to the JDK installation
#   JDTLS_DATA_DIR   - Workspace data directory (default: ~\.cache\jdtls-workspace)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$ScriptDir\lib\common.ps1"

# --- Resolve Java ---
$Java = Resolve-Java
if (-not $Java) {
    if ($script:JavaVersion -and $script:JavaVersion -gt 0) {
        Write-Error "Error: Java 21+ is required, but found Java $($script:JavaVersion)."
    } else {
        Write-Error "Error: Java not found. Set JAVA_HOME or add java to your PATH.`nEclipse JDTLS requires Java 21 or later."
    }
    exit 1
}

# --- Resolve JDTLS ---
$JdtlsHome = Find-Jdtls
if (-not $JdtlsHome) {
    Write-Host "Eclipse JDTLS not found. Downloading latest version..." -ForegroundColor Yellow
    $JdtlsHome = Install-Jdtls
    if (-not $JdtlsHome) {
        Write-Host ""
        Write-Error "Automatic download failed. Please install Eclipse JDTLS manually:`n  Download from: https://download.eclipse.org/jdtls/milestones/`n  Extract and set: JDTLS_HOME=C:\path\to\jdtls"
        exit 1
    }
}

# --- Find the Equinox launcher JAR ---
$LauncherJar = Find-LauncherJar -JdtlsHome $JdtlsHome
if (-not $LauncherJar) {
    Write-Error "Error: Could not find the Equinox launcher JAR in $JdtlsHome\plugins\"
    exit 1
}

# --- Configuration directory ---
$ConfigDir = Get-ConfigDir -JdtlsHome $JdtlsHome
if (-not $ConfigDir) {
    Write-Error "Error: Configuration directory not found: $JdtlsHome\config_win"
    exit 1
}

# --- Workspace data directory ---
$DataDir = if ($env:JDTLS_DATA_DIR) { $env:JDTLS_DATA_DIR } else { "$env:USERPROFILE\.cache\jdtls-workspace" }
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# --- Launch Eclipse JDTLS ---
& $Java `
    "-Declipse.application=org.eclipse.jdt.ls.core.id1" `
    "-Dosgi.bundles.defaultStartLevel=4" `
    "-Declipse.product=org.eclipse.jdt.ls.core.product" `
    "-Dlog.level=WARN" `
    "-Xms512m" `
    "-Xmx2G" `
    "-XX:+UseStringDeduplication" `
    "--add-modules=ALL-SYSTEM" `
    "--add-opens" "java.base/java.util=ALL-UNNAMED" `
    "--add-opens" "java.base/java.lang=ALL-UNNAMED" `
    "-jar" $LauncherJar.FullName `
    "-configuration" $ConfigDir `
    "-data" $DataDir
