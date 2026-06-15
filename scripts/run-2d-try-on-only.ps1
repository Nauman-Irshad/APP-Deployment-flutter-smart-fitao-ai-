# 2D Try-On ONLY — Python API (8765) + Flutter try-on screen (no CV / size / marketplace)
$ErrorActionPreference = "Stop"

$AppRoot = Split-Path $PSScriptRoot -Parent
$TryOnRoot = Join-Path (Split-Path $AppRoot -Parent) "id-2d-try-on"
function Test-PortFree([int]$Port) {
    $c = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return -not $c
}

param(
    [int]$ForcePort = 0
)

$WebPort = if ($ForcePort -gt 0) { $ForcePort } else { 65109 }
if (-not (Test-PortFree $WebPort)) {
    foreach ($p in 65109, 65110, 65111, 65108) {
        if ($p -ne $WebPort -and (Test-PortFree $p)) { $WebPort = $p; break }
    }
}
if (-not (Test-PortFree $WebPort)) {
    Write-Host "Ports 65108-65111 are in use. Stop old Flutter runs (q in terminal) or:" -ForegroundColor Yellow
    Write-Host '  Get-NetTCPConnection -LocalPort 65108 | Select OwningProcess' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $TryOnRoot)) {
    Write-Error "id-2d-try-on not found at: $TryOnRoot"
}

Write-Host ""
Write-Host "=== 2D Try-On only ===" -ForegroundColor Cyan
Write-Host "  API:  http://127.0.0.1:8765  (id-2d-try-on npm run api)"
Write-Host "  App:  http://127.0.0.1:$WebPort  (2D Try On — camera button opens this URL)"
Write-Host "  Camera passes tryon_return=http://127.0.0.1:$WebPort when opened from main app"
Write-Host ""

# Start try-on API in background
$apiJob = Start-Job -ScriptBlock {
    Set-Location $using:TryOnRoot
    npm run api 2>&1
}

Start-Sleep -Seconds 2

Set-Location $AppRoot
flutter run -t lib/main_2d_try_on.dart -d edge `
    --web-port=$WebPort `
    --dart-define=TRYON_API_BASE=http://127.0.0.1:8765 `
    --dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000

# When flutter exits, stop API job
Stop-Job $apiJob -ErrorAction SilentlyContinue
Remove-Job $apiJob -Force -ErrorAction SilentlyContinue
