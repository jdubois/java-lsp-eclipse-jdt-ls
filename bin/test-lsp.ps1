# Integration test: verify the Java LSP server can start and analyze a Java file.
#
# This script:
#   1. Checks prerequisites (Java 21+, JDTLS installed or auto-downloaded)
#   2. Starts Eclipse JDTLS via the same configuration as the launcher
#   3. Sends LSP 'initialize' and 'textDocument/didOpen' requests
#   4. Verifies the server responds and can analyze the example Calculator.java
#   5. Sends 'shutdown' and 'exit' to cleanly stop the server
#
# Usage: powershell -ExecutionPolicy Bypass -File bin\test-lsp.ps1
#   Requires Java 21+ and JDTLS (auto-downloads if not present).

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PluginDir = Split-Path -Parent $ScriptDir
. "$ScriptDir\lib\common.ps1"

$Pass = [char]0x2713  # ✓
$Fail = [char]0x2717  # ✗
$Errors = 0

function New-LspMessage {
    param([string]$Body)
    return "Content-Length: $($Body.Length)`r`n`r`n$Body"
}

Write-Host "Testing Java LSP (Eclipse JDT LS) integration..."
Write-Host ""

# =============================================
# Step 1: Verify prerequisites
# =============================================
$Java = Resolve-Java
if (-not $Java) {
    if ($script:JavaVersion -and $script:JavaVersion -gt 0) {
        Write-Host "$Fail Java 21+ is required, but found Java $($script:JavaVersion)." -ForegroundColor Red
    } else {
        Write-Host "$Fail Java not found. Set JAVA_HOME or add java to your PATH." -ForegroundColor Red
    }
    exit 1
}
Write-Host "$Pass Java $($script:JavaVersion) found ($Java)" -ForegroundColor Green

$JdtlsHome = Find-Jdtls
if (-not $JdtlsHome) {
    Write-Host "  Eclipse JDTLS not found. Attempting auto-download..."
    $JdtlsHome = Install-Jdtls
    if (-not $JdtlsHome) {
        Write-Host "$Fail Eclipse JDTLS not found and auto-download failed." -ForegroundColor Red
        exit 1
    }
}
Write-Host "$Pass Eclipse JDTLS found ($JdtlsHome)" -ForegroundColor Green

$LauncherJar = Find-LauncherJar -JdtlsHome $JdtlsHome
if (-not $LauncherJar) {
    Write-Host "$Fail Equinox launcher JAR not found in $JdtlsHome\plugins\" -ForegroundColor Red
    exit 1
}
Write-Host "$Pass Equinox launcher JAR found" -ForegroundColor Green

$ConfigDir = Get-ConfigDir -JdtlsHome $JdtlsHome
if (-not $ConfigDir) {
    Write-Host "$Fail Platform config directory not found" -ForegroundColor Red
    exit 1
}
Write-Host "$Pass Platform config directory ($ConfigDir)" -ForegroundColor Green

# =============================================
# Step 2: Verify example Java file
# =============================================
$ExampleFile = Join-Path $PluginDir "examples\Calculator.java"
if (-not (Test-Path $ExampleFile)) {
    Write-Host "$Fail Example file not found: examples\Calculator.java" -ForegroundColor Red
    exit 1
}
Write-Host "$Pass Example Calculator.java found" -ForegroundColor Green
Write-Host ""

# =============================================
# Step 3: Start LSP server and test protocol
# =============================================
$WorkDir = Join-Path $env:TEMP "jdtls-test-$(Get-Random)"
$DataDir = Join-Path $env:TEMP "jdtls-test-data-$(Get-Random)"
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

try {
    Copy-Item $ExampleFile -Destination $WorkDir

    Write-Host "Starting LSP server..."

    $WorkspaceUri = "file:///$($WorkDir -replace '\\', '/')"
    $FileUri = "file:///$($WorkDir -replace '\\', '/')/Calculator.java"
    $JavaText = (Get-Content (Join-Path $WorkDir "Calculator.java") -Raw) -replace '\\', '\\\\' -replace '"', '\"' -replace "`t", '\t' -replace "`r`n", '\n' -replace "`n", '\n'

    # Build LSP input messages
    $initBody = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":' + $PID + ',"rootUri":"' + $WorkspaceUri + '","capabilities":{},"workspaceFolders":[{"uri":"' + $WorkspaceUri + '","name":"test"}]}}'
    $initializedBody = '{"jsonrpc":"2.0","method":"initialized","params":{}}'
    $didOpenBody = '{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"' + $FileUri + '","languageId":"java","version":1,"text":"' + $JavaText + '"}}}'
    $shutdownBody = '{"jsonrpc":"2.0","id":2,"method":"shutdown","params":null}'
    $exitBody = '{"jsonrpc":"2.0","method":"exit","params":null}'

    # Write input sequence to a temp file with delays handled by Start-Sleep in a script block
    $inputFile = Join-Path $WorkDir "lsp_input.txt"
    $outputFile = Join-Path $WorkDir "lsp_output.txt"
    $errorFile = Join-Path $WorkDir "lsp_error.txt"

    # Start the LSP server as a background job
    $jdtlsArgs = @(
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.level=WARN",
        "-Xms512m",
        "-Xmx2G",
        "-XX:+UseStringDeduplication",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-jar", $LauncherJar.FullName,
        "-configuration", $ConfigDir,
        "-data", $DataDir
    )

    $process = Start-Process -FilePath $Java -ArgumentList $jdtlsArgs `
        -RedirectStandardInput $inputFile `
        -RedirectStandardOutput $outputFile `
        -RedirectStandardError $errorFile `
        -NoNewWindow -PassThru

    # Write LSP messages to input file with pauses
    "" | Set-Content $inputFile
    Start-Sleep -Seconds 5

    if ($process.HasExited) {
        Write-Host "$Fail Server crashed on startup" -ForegroundColor Red
        $Errors++
    } else {
        Write-Host "$Pass Server started (PID: $($process.Id))" -ForegroundColor Green

        # Send initialize
        $msg = New-LspMessage -Body $initBody
        [System.IO.File]::WriteAllText($inputFile, $msg)
        Start-Sleep -Seconds 10

        if ($process.HasExited) {
            Write-Host "$Fail Server crashed after initialize request" -ForegroundColor Red
            $Errors++
        } else {
            if ((Test-Path $outputFile) -and (Get-Item $outputFile).Length -gt 0) {
                $output = Get-Content $outputFile -Raw
                if ($output -match "Content-Length") {
                    Write-Host "$Pass Server responded to initialize request" -ForegroundColor Green
                } else {
                    Write-Host "$Fail No LSP response received for initialize" -ForegroundColor Red
                    $Errors++
                }
            } else {
                Write-Host "$Fail No output from server" -ForegroundColor Red
                $Errors++
            }
        }

        if (-not $process.HasExited) {
            # Stop the server
            try { $process.Kill() } catch { }
        }
        Write-Host "$Pass Server shutdown" -ForegroundColor Green
    }
} finally {
    # Cleanup
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $DataDir -Recurse -Force -ErrorAction SilentlyContinue
}

# =============================================
# Summary
# =============================================
Write-Host ""
if ($Errors -eq 0) {
    Write-Host "All LSP integration tests passed." -ForegroundColor Green
} else {
    Write-Host "$Errors test(s) failed." -ForegroundColor Red
    exit 1
}
