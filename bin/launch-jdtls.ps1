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

$JdtlsInstallDir = "$env:LOCALAPPDATA\jdtls"
$JdtlsMilestonesUrl = "https://download.eclipse.org/jdtls/milestones"

# --- Resolve Java executable ---
$Java = $null
if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
    $Java = "$env:JAVA_HOME\bin\java.exe"
} else {
    $Java = (Get-Command java -ErrorAction SilentlyContinue).Source
}

if (-not $Java) {
    Write-Error "Error: Java not found. Set JAVA_HOME or add java to your PATH.`nEclipse JDTLS requires Java 21 or later."
    exit 1
}

# --- Verify Java version >= 21 ---
$VersionOutput = & $Java -version 2>&1 | Select-Object -First 1
if ($VersionOutput -match '"(\d+)') {
    $JavaVersion = [int]$Matches[1]
    if ($JavaVersion -lt 21) {
        Write-Error "Error: Java 21+ is required, but found Java $JavaVersion."
        exit 1
    }
}

# --- Find JDTLS installation ---
function Find-Jdtls {
    if ($env:JDTLS_HOME -and (Test-Path "$env:JDTLS_HOME\plugins")) {
        return $env:JDTLS_HOME
    }
    $Candidates = @(
        $JdtlsInstallDir,
        "$env:ProgramFiles\jdtls",
        "$env:USERPROFILE\jdtls",
        "$env:USERPROFILE\.local\share\jdtls",
        "C:\jdtls"
    )
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path "$candidate\plugins")) {
            return $candidate
        }
    }
    return $null
}

# --- Download JDTLS if not found ---
function Install-Jdtls {
    Write-Host "Eclipse JDTLS not found. Downloading latest version..." -ForegroundColor Yellow

    # Find latest version from milestones page
    try {
        $Page = Invoke-WebRequest -Uri "$JdtlsMilestonesUrl/" -UseBasicParsing
        $Versions = [regex]::Matches($Page.Content, '1\.\d+\.\d+') |
            ForEach-Object { $_.Value } |
            Sort-Object { [version]$_ } -Unique
        $LatestVersion = $Versions[-1]
    } catch {
        Write-Error "Error: Could not determine the latest JDTLS version."
        return $null
    }
    Write-Host "Latest version: $LatestVersion" -ForegroundColor Cyan

    # Get exact filename from latest.txt
    try {
        $Filename = (Invoke-WebRequest -Uri "$JdtlsMilestonesUrl/$LatestVersion/latest.txt" -UseBasicParsing).Content.Trim()
    } catch {
        Write-Error "Error: Could not determine the download filename for JDTLS $LatestVersion."
        return $null
    }

    $DownloadUrl = "$JdtlsMilestonesUrl/$LatestVersion/$Filename"
    $TempFile = "$env:TEMP\$Filename"
    Write-Host "Downloading from: $DownloadUrl" -ForegroundColor Cyan

    # Download
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing
    } catch {
        Write-Error "Error: Download failed."
        return $null
    }

    # Extract
    if (-not (Test-Path $JdtlsInstallDir)) {
        New-Item -ItemType Directory -Path $JdtlsInstallDir -Force | Out-Null
    }
    try {
        tar xzf $TempFile -C $JdtlsInstallDir
        Remove-Item $TempFile -Force
        Write-Host "Eclipse JDTLS $LatestVersion installed to $JdtlsInstallDir" -ForegroundColor Green
        return $JdtlsInstallDir
    } catch {
        Write-Error "Error: Extraction failed. Ensure tar is available (Windows 10+)."
        return $null
    }
}

# --- Resolve JDTLS ---
$JdtlsHome = Find-Jdtls
if (-not $JdtlsHome) {
    $JdtlsHome = Install-Jdtls
    if (-not $JdtlsHome) {
        Write-Host ""
        Write-Error "Automatic download failed. Please install Eclipse JDTLS manually:`n  Download from: https://download.eclipse.org/jdtls/milestones/`n  Extract and set: JDTLS_HOME=C:\path\to\jdtls"
        exit 1
    }
}

# --- Find the Equinox launcher JAR ---
$LauncherJar = Get-ChildItem -Path "$JdtlsHome\plugins" -Filter "org.eclipse.equinox.launcher_*.jar" | Select-Object -First 1

if (-not $LauncherJar) {
    Write-Error "Error: Could not find the Equinox launcher JAR in $JdtlsHome\plugins\"
    exit 1
}

# --- Configuration directory (Windows) ---
$ConfigDir = "$JdtlsHome\config_win"
if (-not (Test-Path $ConfigDir)) {
    Write-Error "Error: Configuration directory not found: $ConfigDir"
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
    "-Dlog.level=ALL" `
    "-Xmx1G" `
    "--add-modules=ALL-SYSTEM" `
    "--add-opens" "java.base/java.util=ALL-UNNAMED" `
    "--add-opens" "java.base/java.lang=ALL-UNNAMED" `
    "-jar" $LauncherJar.FullName `
    "-configuration" $ConfigDir `
    "-data" $DataDir
