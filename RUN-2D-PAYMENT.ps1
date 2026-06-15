# 2D try-on on http://localhost:65109 WITH Stripe payment
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-2D-PAYMENT.ps1

$ErrorActionPreference = "Stop"
$AppRoot = $PSScriptRoot
$WsRoot = Split-Path $AppRoot -Parent
$StripeRoot = Join-Path $WsRoot "strip payment gateway"
$TryOnRoot = Join-Path $WsRoot "id-2d-try-on"

function Start-Window([string]$Title, [string]$Command) {
    $t = $Title -replace "'", "''"
    Start-Process powershell -ArgumentList @("-NoExit", "-Command", "`$Host.UI.RawUI.WindowTitle = '$t'; $Command") | Out-Null
    Write-Host "  Started: $Title" -ForegroundColor Green
}

Write-Host "`n=== 2D Try-On + Payment (localhost:65109) ===" -ForegroundColor Cyan

if (Test-Path (Join-Path $StripeRoot "RUN-STRIPE-SERVER.ps1")) {
    $stripeCmd = @"
Remove-Item Env:STRIPE_MOCK_CHECKOUT -ErrorAction SilentlyContinue
Remove-Item Env:STRIPE_FALLBACK_MOCK -ErrorAction SilentlyContinue
& '$((Join-Path $StripeRoot 'RUN-STRIPE-SERVER.ps1') -replace "'", "''")'"
    Start-Window "Stripe LIVE :8000" $stripeCmd
    Start-Sleep -Seconds 3
}

if (Test-Path (Join-Path $TryOnRoot "package.json")) {
    $apiCmd = @"
Set-Location '$($TryOnRoot -replace "'", "''")'
npm run api
"@
    Start-Window "2D API :8765" $apiCmd
    Start-Sleep -Seconds 2
}

$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Set-Location $AppRoot
Write-Host "Open: http://localhost:65109" -ForegroundColor Green
Write-Host "Flow: try-on -> Find tailor -> chat -> Final cart -> Pay with Stripe" -ForegroundColor DarkGray
flutter run -t lib/main_2d_try_on.dart -d edge --web-port=65109 `
  --dart-define=TRYON_API_BASE=http://127.0.0.1:8765 `
  --dart-define=TRYON_APP_BASE=http://localhost:65109 `
  --dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000 `
  --dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003
