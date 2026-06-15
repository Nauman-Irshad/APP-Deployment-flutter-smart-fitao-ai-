# User app + Stripe payment (backends + Flutter on Edge)
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-WITH-PAYMENT.ps1
#
# Stripe only:
#   cd "E:\fyp whole backend\strip payment gateway"
#   .\RUN-STRIPE-SERVER.ps1

$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

& "$PSScriptRoot\RUN-ALL-BACKEND-SERVICES.ps1"

$stripeRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "strip payment gateway"
if (Test-Path (Join-Path $stripeRoot "RUN-STRIPE-SERVER.ps1")) {
    $cmd = "& '$((Join-Path $stripeRoot 'RUN-STRIPE-SERVER.ps1') -replace "'", "''")'"
    Start-Process powershell -ArgumentList @(
        "-NoExit", "-Command",
        "`$Host.UI.RawUI.WindowTitle = 'SmartFitao Stripe :8000'; $cmd"
    ) | Out-Null
    Write-Host "  Started: Stripe :8000" -ForegroundColor Green
    Start-Sleep -Seconds 3
}

Set-Location $PSScriptRoot
Write-Host ""
Write-Host "Launching app with payment on http://127.0.0.1:65106 ..." -ForegroundColor Green
flutter run -d edge --web-port=65106 `
  --dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000 `
  --dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001 `
  --dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003 `
  --dart-define=TRYON_API_BASE=http://127.0.0.1:8765 `
  --dart-define=LOCAL_PRODUCT_API_BASE=http://127.0.0.1:5190 `
  --dart-define=CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/
