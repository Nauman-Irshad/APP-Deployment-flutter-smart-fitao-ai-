# 2D Try-On: API :8765 + Flutter app :65109 on Edge
# Camera redirects here with ?handoff= after capture on :5003
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-2D-TRYON.ps1

$ErrorActionPreference = "Stop"
$AppRoot = $PSScriptRoot
$TryOnRoot = Join-Path (Split-Path $AppRoot -Parent) "id-2d-try-on"
. "$AppRoot\scripts\Invoke-FlutterWebSafe.ps1"

if (-not (Test-Path (Join-Path $TryOnRoot "package.json"))) {
    Write-Error "id-2d-try-on not found: $TryOnRoot"
}

function Start-Window([string]$Title, [string]$Command) {
    $t = $Title -replace "'", "''"
    Start-Process powershell -ArgumentList @("-NoExit", "-Command", "`$Host.UI.RawUI.WindowTitle = '$t'; $Command") | Out-Null
    Write-Host "  Started: $Title" -ForegroundColor Green
}

Write-Host "`n=== 2D Try-On ===" -ForegroundColor Cyan

if (-not (Test-WebPortListening 8765)) {
    $apiCmd = @"
Set-Location '$($TryOnRoot -replace "'", "''")'
Write-Host 'Try-on API http://127.0.0.1:8765' -ForegroundColor Cyan
npm run api
"@
    Start-Window "2D Try-On API :8765" $apiCmd
    Write-Host "Waiting for API..." -ForegroundColor Yellow
    for ($i = 0; $i -lt 30; $i++) {
        if (Test-WebPortListening 8765) { break }
        Start-Sleep -Seconds 2
    }
}

$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Set-Location $AppRoot
Write-Host "Stripe (optional): cd strip payment gateway; .\RUN-STRIPE-SERVER.ps1" -ForegroundColor DarkGray

$defines = @(
    '-t', 'lib/main_2d_try_on.dart',
    '--dart-define=TRYON_API_BASE=http://127.0.0.1:8765',
    '--dart-define=TRYON_APP_BASE=http://127.0.0.1:65109',
    '--dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000',
    '--dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003'
)

Invoke-FlutterWebSafe -Label '2D Try-On' -Port 65109 -OpenBrowser -FlutterArgs $defines
