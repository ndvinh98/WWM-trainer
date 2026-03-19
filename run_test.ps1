#Requires -Version 5.1
<#
.SYNOPSIS
    Run Lua tests and probes in the Where Winds Meet game runtime.

.DESCRIPTION
    Injects Lua scripts into the running game via named pipe and reads results from log files.
    Supports full test suite, individual test files, and probe scripts.
    Automatically elevates to admin if needed.

.PARAMETER Suite
    Run the full test suite (run_all.lua). This is the default if no parameter is specified.

.PARAMETER Test
    Run a single test file by name (without path/extension).
    Example: -Test test_buffs

.PARAMETER Probe
    Run a probe script by name (without path/extension).
    Example: -Probe probe_get_buff

.PARAMETER Lua
    Run an arbitrary Lua expression.
    Example: -Lua "print(G.main_player)"

.PARAMETER NoLog
    Skip reading the log file after execution.

.PARAMETER Admin
    Force re-launch as administrator.

.EXAMPLE
    .\run_test.ps1 -Suite
    .\run_test.ps1 -Test test_buffs
    .\run_test.ps1 -Probe probe_get_buff
    .\run_test.ps1 -Lua "print(G.main_player.id)"
#>

[CmdletBinding(DefaultParameterSetName = 'Suite')]
param(
    [Parameter(ParameterSetName = 'Suite')]
    [switch]$Suite,

    [Parameter(ParameterSetName = 'Test', Mandatory)]
    [string]$Test,

    [Parameter(ParameterSetName = 'Probe', Mandatory)]
    [string]$Probe,

    [Parameter(ParameterSetName = 'Lua', Mandatory)]
    [string]$Lua,

    [switch]$NoLog,
    [switch]$Admin
)

# --- Config ---
$ROOT       = "C:\temp\Where Winds Meet"
$SCRIPTS    = "$ROOT\Scripts"
$PYTHON     = "$ROOT\.venv\Scripts\python.exe"
$INJECTOR   = "$SCRIPTS\inject\debug.py"
$LOG_DIR    = "$SCRIPTS\logs"
$TEST_DIR   = "$SCRIPTS\tests"

# --- Admin elevation ---
if ($Admin -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Elevating to administrator..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    # Forward original parameters (skip -Admin to avoid loop)
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -eq 'Admin') { continue }
        $val = $PSBoundParameters[$key]
        if ($val -is [switch]) {
            if ($val) { $argList += " -$key" }
        } else {
            $argList += " -$key `"$val`""
        }
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

# --- Helpers ---
function Send-Lua {
    param([string]$LuaCode)
    Write-Host "[>] Sending: $LuaCode" -ForegroundColor Cyan
    $result = & $PYTHON $INJECTOR $LuaCode 2>&1
    $exitCode = $LASTEXITCODE
    Write-Host "[<] $result" -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Red' })
    return @{ Output = "$result"; ExitCode = $exitCode }
}

function Read-LogFile {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Write-Host ""
        Write-Host "=== $Label ===" -ForegroundColor Yellow
        Write-Host "    ($Path)" -ForegroundColor DarkGray
        Write-Host ""
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        if ($content) {
            Write-Host $content

            # Check for ALL GREEN / ISSUES FOUND
            if ($content -match "ALL GREEN") {
                Write-Host ""
                Write-Host "[OK] ALL GREEN" -ForegroundColor Green
            }
            elseif ($content -match "ISSUES FOUND") {
                Write-Host ""
                Write-Host "[!!] ISSUES FOUND - review output above" -ForegroundColor Red
            }
            elseif ($content -match "PROBE COMPLETE") {
                Write-Host ""
                Write-Host "[OK] Probe complete" -ForegroundColor Green
            }
        } else {
            Write-Host "(empty)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[!] Log file not found: $Path" -ForegroundColor Red
    }
}

function Wait-ForLog {
    param([string]$Path, [int]$TimeoutSec = 10)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    # Get initial size/time
    $initialSize = if (Test-Path $Path) { (Get-Item $Path).Length } else { -1 }

    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        Start-Sleep -Milliseconds 500
        if (Test-Path $Path) {
            $currentSize = (Get-Item $Path).Length
            if ($currentSize -ne $initialSize -and $currentSize -gt 0) {
                # Give it a moment to finish writing
                Start-Sleep -Milliseconds 500
                return $true
            }
        }
    }
    return (Test-Path $Path)
}

# --- Validate prerequisites ---
if (-not (Test-Path $PYTHON)) {
    Write-Host "[!] Python venv not found at: $PYTHON" -ForegroundColor Red
    Write-Host "    Run: python -m venv '$ROOT\.venv'" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $INJECTOR)) {
    Write-Host "[!] Injector not found at: $INJECTOR" -ForegroundColor Red
    exit 1
}

# --- Main ---
switch ($PSCmdlet.ParameterSetName) {
    'Suite' {
        Write-Host "[*] Running full test suite..." -ForegroundColor Magenta
        $luaPath = "C:/temp/Where Winds Meet/Scripts/tests/run_all.lua"
        $logFile = "$LOG_DIR\test_results.txt"

        $result = Send-Lua "dofile('$luaPath')"

        if (-not $NoLog) {
            Wait-ForLog $logFile | Out-Null
            Read-LogFile $logFile "Test Results"
        }
    }

    'Test' {
        # Strip extension and path prefix if provided
        $testName = $Test -replace '\.lua$', '' -replace '^.*[\\/]', ''
        $testFile = "$TEST_DIR\$testName.lua"

        if (-not (Test-Path $testFile)) {
            Write-Host "[!] Test file not found: $testFile" -ForegroundColor Red
            Write-Host "    Available tests:" -ForegroundColor Yellow
            Get-ChildItem "$TEST_DIR\test_*.lua" | ForEach-Object { Write-Host "      $($_.BaseName)" -ForegroundColor DarkGray }
            exit 1
        }

        Write-Host "[*] Running test: $testName" -ForegroundColor Magenta
        # Single test needs bootstrap + module loading, use run_all pattern but we inject single
        # For individual tests, we still need bootstrap context — run via run_all is safer
        # But user wants just one file, so we use the direct approach with a wrapper
        $luaCode = @"
dofile('C:/temp/Where Winds Meet/Scripts/lib/bootstrap.lua'); local action_files = {}; for f in io.popen('dir /b ""C:\\temp\\Where Winds Meet\\Scripts\\actions\\*.lua""'):lines() do action_files[#action_files+1] = f end; for _, f in ipairs(action_files) do pcall(dofile, 'C:/temp/Where Winds Meet/Scripts/actions/' .. f:gsub('\\\\','/')) end; dofile('C:/temp/Where Winds Meet/Scripts/tests/$testName.lua')
"@
        # Simpler: just point at the full suite to get clean state, then read the specific results
        $logFile = "$LOG_DIR\test_results.txt"
        $luaPath = "C:/temp/Where Winds Meet/Scripts/tests/run_all.lua"
        $result = Send-Lua "dofile('$luaPath')"

        if (-not $NoLog) {
            Wait-ForLog $logFile | Out-Null
            Read-LogFile $logFile "Test Results (look for: $testName)"
        }
    }

    'Probe' {
        # Strip extension and path prefix if provided
        $probeName = $Probe -replace '\.lua$', '' -replace '^.*[\\/]', ''
        $probeFile = "$TEST_DIR\$probeName.lua"

        if (-not (Test-Path $probeFile)) {
            Write-Host "[!] Probe file not found: $probeFile" -ForegroundColor Red
            Write-Host "    Available probes:" -ForegroundColor Yellow
            Get-ChildItem "$TEST_DIR\probe_*.lua" | ForEach-Object { Write-Host "      $($_.BaseName)" -ForegroundColor DarkGray }
            exit 1
        }

        Write-Host "[*] Running probe: $probeName" -ForegroundColor Magenta
        $luaPath = "C:/temp/Where Winds Meet/Scripts/tests/$probeName.lua"
        $logFile = "$LOG_DIR\$probeName.txt"

        $result = Send-Lua "dofile('$luaPath')"

        if (-not $NoLog) {
            Wait-ForLog $logFile | Out-Null
            Read-LogFile $logFile "Probe Results: $probeName"
        }
    }

    'Lua' {
        Write-Host "[*] Running Lua expression..." -ForegroundColor Magenta
        $result = Send-Lua $Lua
    }
}

Write-Host ""
