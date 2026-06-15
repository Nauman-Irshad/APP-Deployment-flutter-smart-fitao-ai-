# Marketplace on Edge + Stripe payment (two terminals: Stripe API + Flutter)
$ErrorActionPreference = "Stop"
$appRoot = $PSScriptRoot
$stripeRoot = Join-Path (Split-Path $appRoot -Parent) "strip payment gateway"

Write-Host "1) Opening Stripe server (port 8000) in a new window..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$stripeRoot'; .\RUN-STRIPE-SERVER.ps1"
) | Out-Null

Write-Host "2) Waiting for Stripe API..." -ForegroundColor DarkGray
Start-Sleep -Seconds 4

Set-Location $appRoot
Write-Host "3) Launching Flutter on Edge (from App folder)..." -ForegroundColor Green
flutter run -d edge `
  --dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001 `
  --dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000
