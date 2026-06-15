# WEB ONLY — http://127.0.0.1:65106 (does NOT rebuild phone APK)
# Code edits here affect Edge after hot reload / restart — phone APK unchanged until RUN-BUILD-APK-LIVE.ps1
# See: DEV-WEB-VS-APK.md
# First run: .\RUN-EDGE-LOCAL-BACKEND.ps1
param(
    [switch]$LiveSizeApi,
    [switch]$ForceRestart
)

$ErrorActionPreference = 'Stop'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Set-Location $PSScriptRoot
. "$PSScriptRoot\scripts\Invoke-FlutterWebSafe.ps1"

$render = 'https://fyp-backend-hi10.onrender.com'
$shop = 'https://fyp-web-code-deployment-flea.vercel.app'
$cvLive = 'https://qr-code-scan-computer-visionj-git-main-nauman-irshads-projects.vercel.app'
$r2 = 'https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev'

$defines = @(
    "--dart-define=CLOTH_STUDIO_URL=$shop/",
    "--dart-define=MEDIA_CDN_BASE=$r2/"
)

if ($LiveSizeApi) {
    $defines += "--dart-define=CLOTH_PREDICT_BASE=$render"
    $defines += '--dart-define=SIZE_API_LOCAL=false'
    $defines += "--dart-define=CV_CAMERA_BASE=$cvLive"
    $defines += "--dart-define=TRYON_API_BASE=$shop"
    Write-Host 'LIVE: Render + Vercel CV (phone-like)' -ForegroundColor Yellow
} else {
    $defines += '--dart-define=SIZE_API_LOCAL=true'
    $defines += '--dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001'
    $defines += '--dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003'
    $defines += '--dart-define=TRYON_API_BASE=http://127.0.0.1:8765'
    $defines += '--dart-define=TRYON_APP_BASE=http://127.0.0.1:65106'
    $defines += '--dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000'
    $defines += '--dart-define=SMARTFITAO_CHAT_URL=http://127.0.0.1:5002/'
    Write-Host 'LOCAL: Size :5001  Camera :5003  2D :8765  Stripe :8000  Chat :5002' -ForegroundColor Green
}

Write-Host '3D + Reels: R2 CDN' -ForegroundColor Green

Invoke-FlutterWebSafe -Label 'Marketplace' -Port 65106 -OpenBrowser -FlutterArgs $defines -ForceRestart:$ForceRestart
