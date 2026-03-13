# Shared functions for Java LSP plugin scripts.
# Dot-source this file — do not execute directly.
#
# After sourcing, the following functions and variables are available:
#   Resolve-Java   - Returns Java path or $null; sets $script:JavaVersion
#   Find-Jdtls     - Returns JDTLS home path or $null
#   Install-Jdtls  - Downloads latest JDTLS, returns install path or $null
#   Find-LauncherJar  - Returns launcher JAR FileInfo or $null
#   Get-ConfigDir     - Returns platform config directory path or $null

$script:JdtlsInstallDir = "$env:LOCALAPPDATA\jdtls"
$script:JdtlsMilestonesUrl = "https://download.eclipse.org/jdtls/milestones"
$script:JavaVersion = 0

function Resolve-Java {
    $java = $null
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        $java = "$env:JAVA_HOME\bin\java.exe"
    } else {
        $java = (Get-Command java -ErrorAction SilentlyContinue).Source
    }

    if (-not $java) { return $null }

    $versionOutput = & $java -version 2>&1 | Select-Object -First 1
    if ($versionOutput -match '"(\d+)') {
        $script:JavaVersion = [int]$Matches[1]
        if ($script:JavaVersion -lt 21) { return $null }
    }

    return $java
}

function Find-Jdtls {
    if ($env:JDTLS_HOME -and (Test-Path "$env:JDTLS_HOME\plugins")) {
        return $env:JDTLS_HOME
    }
    $candidates = @(
        $script:JdtlsInstallDir,
        "$env:ProgramFiles\jdtls",
        "$env:USERPROFILE\jdtls",
        "$env:USERPROFILE\.local\share\jdtls",
        "C:\jdtls"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path "$candidate\plugins")) {
            return $candidate
        }
    }
    return $null
}

function Install-Jdtls {
    try {
        $page = Invoke-WebRequest -Uri "$($script:JdtlsMilestonesUrl)/" -UseBasicParsing
        $versions = [regex]::Matches($page.Content, '1\.\d+\.\d+') |
            ForEach-Object { $_.Value } |
            Sort-Object { [version]$_ } -Unique
        $latestVersion = $versions[-1]
    } catch {
        Write-Host "Error: Could not determine the latest JDTLS version." -ForegroundColor Red
        return $null
    }
    Write-Host "Latest version: $latestVersion" -ForegroundColor Cyan

    try {
        $filename = (Invoke-WebRequest -Uri "$($script:JdtlsMilestonesUrl)/$latestVersion/latest.txt" -UseBasicParsing).Content.Trim()
    } catch {
        Write-Host "Error: Could not determine the download filename for JDTLS $latestVersion." -ForegroundColor Red
        return $null
    }

    $downloadUrl = "$($script:JdtlsMilestonesUrl)/$latestVersion/$filename"
    $tempFile = "$env:TEMP\$filename"
    Write-Host "Downloading from: $downloadUrl" -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    } catch {
        Write-Host "Error: Download failed." -ForegroundColor Red
        return $null
    }

    if (-not (Test-Path $script:JdtlsInstallDir)) {
        New-Item -ItemType Directory -Path $script:JdtlsInstallDir -Force | Out-Null
    }
    try {
        tar xzf $tempFile -C $script:JdtlsInstallDir
        Remove-Item $tempFile -Force
        Write-Host "Eclipse JDTLS $latestVersion installed to $($script:JdtlsInstallDir)" -ForegroundColor Green
        return $script:JdtlsInstallDir
    } catch {
        Write-Host "Error: Extraction failed. Ensure tar is available (Windows 10+)." -ForegroundColor Red
        return $null
    }
}

function Find-LauncherJar {
    param([string]$JdtlsHome)
    if (-not $JdtlsHome -or -not (Test-Path "$JdtlsHome\plugins")) { return $null }
    return Get-ChildItem -Path "$JdtlsHome\plugins" -Filter "org.eclipse.equinox.launcher_*.jar" | Select-Object -First 1
}

function Get-ConfigDir {
    param([string]$JdtlsHome)
    if (-not $JdtlsHome) { return $null }
    $configDir = "$JdtlsHome\config_win"
    if (Test-Path $configDir) { return $configDir }
    return $null
}
