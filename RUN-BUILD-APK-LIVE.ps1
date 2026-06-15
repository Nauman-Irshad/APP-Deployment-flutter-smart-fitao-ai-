# PHONE APK ONLY — live URLs (Render, Vercel, R2). Does NOT run Edge.
# Web dev: use RUN-EDGE-MARKETPLACE.ps1 — same lib/ code, but phone updates ONLY when you run THIS script.
# See: DEV-WEB-VS-APK.md
# Stripe live (after Render deploy): https://smartfitao-stripe-api.onrender.com
#   .\RUN-BUILD-APK-LIVE.ps1 -StripeBase "https://smartfitao-stripe-api.onrender.com"
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-BUILD-APK-LIVE.ps1

param(
    [string]$StripeBase = '',
    [string]$MediaCdnBase = 'https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$shop = 'https://fyp-web-code-deployment-flea.vercel.app'
$render = 'https://fyp-backend-hi10.onrender.com'
$cv = 'https://qr-code-scan-computer-visionj-git-main-nauman-irshads-projects.vercel.app'

$defines = @(
    "--dart-define=CLOTH_PREDICT_BASE=$render",
    "--dart-define=CLOTH_STUDIO_URL=$shop/",
    "--dart-define=TRYON_API_BASE=$shop",
    "--dart-define=CV_CAMERA_BASE=$cv",
    "--dart-define=SIZE_API_LOCAL=false"
)

if ($MediaCdnBase.Trim()) {
    $base = $MediaCdnBase.Trim().TrimEnd('/')
    $defines += "--dart-define=MEDIA_CDN_BASE=$base/"
    Write-Host "Media CDN (Cloudflare R2 etc.): $base/" -ForegroundColor Green
}

if ($StripeBase.Trim()) {
    $defines += "--dart-define=STRIPE_PAYMENT_BASE=$($StripeBase.Trim().TrimEnd('/'))"
    Write-Host "Stripe live: $StripeBase" -ForegroundColor Green
} else {
    Write-Host "Demo build: Size, Camera, 2D Try-on, Chat = LIVE. Stripe Pay = skipped." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== Live in APK ===" -ForegroundColor Cyan
Write-Host "  Size:    $render"
Write-Host "  2D:      $shop/api/tryon"
Write-Host "  3D:      $shop"
Write-Host "  Camera:  $cv"
Write-Host "  3D/Reels: R2 CDN"
Write-Host "  Phone:   NO localhost - internet required"
Write-Host ""

flutter pub get
$cmd = "flutter build apk --release $($defines -join ' ')"
Write-Host $cmd -ForegroundColor White
Invoke-Expression $cmd

$apk = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
Write-Host ""
if (Test-Path $apk) {
    Write-Host "APK ready: $apk" -ForegroundColor Green
    Write-Host "Copy to phone and install. Internet required." -ForegroundColor Green
} else {
    Write-Host "Build failed - see errors above." -ForegroundColor Yellow
}
