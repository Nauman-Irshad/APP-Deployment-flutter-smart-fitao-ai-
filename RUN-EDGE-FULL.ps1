# ONE COMMAND — full SmartFitao user app on Microsoft Edge (no APK)
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-EDGE-FULL.ps1
#
# Starts (separate windows): Size :5001 | 2D :8765 | Stripe :8000 | NLP :5002 (optional)
# Computer Vision (:5003) is skipped — flow goes Size prediction → 2D try-on → tailor chat.
# Then opens: http://127.0.0.1:65106
#
# Guide: EDGE-FULL-GUIDE.md

param(
    [switch]$BackendsOnly,
    [switch]$SkipNlp,
    [switch]$SkipStripe,
    [switch]$SkipCv,
    [switch]$FixFlutter,
    [switch]$ForceAppRestart
)

$ErrorActionPreference = 'Stop'
$AppRoot = $PSScriptRoot
$WsRoot = Split-Path $AppRoot -Parent

# Default: no computer-vision step — size prediction goes straight to 2D try-on.
if (-not $PSBoundParameters.ContainsKey('SkipCv')) { $SkipCv = $true }

$SizeScript = Join-Path $WsRoot "pifuhd-main\Ai Cloth Size Prediction\start-flask.ps1"
$CvDir = Join-Path $WsRoot "Computer Vision (Camera Work)"
$TryOnRoot = Join-Path $WsRoot "id-2d-try-on"
$StripeScript = Join-Path $WsRoot "strip payment gateway\RUN-STRIPE-SERVER.ps1"
$NlpRoot = Join-Path $WsRoot "nlp chat bot"
$R2 = 'https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev'
$Shop = 'https://fyp-web-code-deployment-flea.vercel.app'

foreach ($p in @(
        @{ Name = 'Size script'; Path = $SizeScript },
        @{ Name = 'CV app.py'; Path = Join-Path $CvDir 'app.py' },
        @{ Name = 'id-2d-try-on'; Path = Join-Path $TryOnRoot 'package.json' }
    )) {
    if (-not (Test-Path $p.Path)) { Write-Error "Missing $($p.Name): $($p.Path)" }
}

. "$AppRoot\scripts\Invoke-FlutterWebSafe.ps1"

function Start-Win([string]$Title, [string]$Command) {
    $t = $Title -replace "'", "''"
    Start-Process powershell -ArgumentList @(
        '-NoExit', '-Command', "`$Host.UI.RawUI.WindowTitle = '$t'; $Command"
    ) | Out-Null
    Write-Host "  Started: $Title" -ForegroundColor Green
}

function Start-WinIfNeeded([string]$Title, [string]$Command, [string]$HealthUrl) {
    if (Test-Ok $HealthUrl) {
        Write-Host "  Already up: $Title" -ForegroundColor DarkGray
        return
    }
    Start-Win $Title $Command
}

function Test-Ok([string]$Url) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 4
        return $r.StatusCode -lt 500
    } catch { return $false }
}

Write-Host ''
Write-Host '=== SmartFitao EDGE — full user app ===' -ForegroundColor Cyan
Write-Host ''

# --- Backends (skip window if health URL already OK — avoids duplicate :8765 listeners) ---
$sizeCmd = "& '$($SizeScript -replace "'", "''")'"
Start-WinIfNeeded 'Size prediction :5001' $sizeCmd 'http://127.0.0.1:5001/api/health'

$cvCmd = @"
Set-Location '$($CvDir -replace "'", "''")'
`$env:SMARTFITAO_HTTP = '1'
`$env:CAMERA_APP_PORT = '5003'
python app.py
"@
if (-not $SkipCv) {
    Start-WinIfNeeded 'Computer Vision :5003' $cvCmd 'http://127.0.0.1:5003/'
} else {
    Write-Host '  [SKIP] Computer Vision — size prediction goes straight to 2D try-on' -ForegroundColor DarkGray
}

$tryCmd = @"
Set-Location '$($TryOnRoot -replace "'", "''")'
Write-Host '2D Try-on API http://127.0.0.1:8765 (real HF — set TRYON_MOCK/TRYON_FAST in id-2d-try-on/.env)' -ForegroundColor Cyan
npm run api
"@
Start-WinIfNeeded '2D Try-on API :8765' $tryCmd 'http://127.0.0.1:8765/health'

if (-not $SkipStripe) {
    if (Test-Path $StripeScript) {
        $stripeCmd = "& '$($StripeScript -replace "'", "''")'"
        Start-WinIfNeeded 'Stripe payment :8000' $stripeCmd 'http://127.0.0.1:8000/'
    } else {
        Write-Host '  [SKIP] Stripe script not found' -ForegroundColor Yellow
    }
} else {
    Write-Host '  [SKIP] Stripe (-SkipStripe)' -ForegroundColor DarkGray
}

if (-not $SkipNlp) {
    if (Test-Path (Join-Path $NlpRoot 'main.py')) {
        $nlpCmd = @"
Set-Location '$($NlpRoot -replace "'", "''")'
Write-Host 'NLP chatbot API http://127.0.0.1:5002' -ForegroundColor Cyan
python main.py
"@
        Start-WinIfNeeded 'NLP chatbot :5002' $nlpCmd 'http://127.0.0.1:5002/'
    }
} else {
    Write-Host '  [SKIP] NLP (-SkipNlp) — chat still works in app (bundled FAQ)' -ForegroundColor DarkGray
}

Write-Host ''
Write-Host 'Waiting for backends (first Size load can take ~60s)...' -ForegroundColor Yellow
$waitStarted = Get-Date
$deadline = $waitStarted.AddSeconds(120)
$ok = @{ size = $false; cv = $SkipCv; try = $false; stripe = $SkipStripe; nlp = $SkipNlp }

while ((Get-Date) -lt $deadline) {
    if (-not $ok.size) {
        $ok.size = (Test-Ok 'http://127.0.0.1:5001/api/health') -or (Test-Ok 'http://127.0.0.1:5001/')
    }
    if (-not $ok.cv) { $ok.cv = Test-Ok 'http://127.0.0.1:5003/' }
    if (-not $ok.try) {
        $ok.try = (Test-Ok 'http://127.0.0.1:8765/health') -or (Test-Ok 'http://127.0.0.1:8765/docs') -or (Test-Ok 'http://127.0.0.1:8765/')
    }
    if (-not $ok.stripe) { $ok.stripe = Test-Ok 'http://127.0.0.1:8000/' }
    if (-not $ok.nlp) { $ok.nlp = Test-Ok 'http://127.0.0.1:5002/' }
    $coreReady = $ok.size -and ($SkipCv -or $ok.cv) -and $ok.try -and $ok.stripe
    if ($coreReady -and ($SkipNlp -or $ok.nlp)) { break }
    if ($coreReady -and -not $SkipNlp -and -not $ok.nlp -and (((Get-Date) - $waitStarted).TotalSeconds -gt 30)) {
        Write-Host '  NLP :5002 still starting — continuing (chat uses bundled FAQ if API down)' -ForegroundColor DarkGray
        break
    }
    Start-Sleep -Seconds 3
}

Write-Host ''
Write-Host 'Backend status:' -ForegroundColor Cyan
Write-Host ("  Size prediction  :5001  " + $(if ($ok.size) { 'OK' } else { 'starting — check window' })) -ForegroundColor $(if ($ok.size) { 'Green' } else { 'Yellow' })
if ($SkipCv) {
    Write-Host '  Computer vision  :5003  skipped (direct to 2D try-on)' -ForegroundColor DarkGray
} else {
    Write-Host ("  Computer vision  :5003  " + $(if ($ok.cv) { 'OK' } else { 'starting' })) -ForegroundColor $(if ($ok.cv) { 'Green' } else { 'Yellow' })
}
Write-Host ("  2D try-on API    :8765  " + $(if ($ok.try) { 'OK' } else { 'starting' })) -ForegroundColor $(if ($ok.try) { 'Green' } else { 'Yellow' })
if (-not $SkipStripe) {
    Write-Host ("  Stripe pay       :8000  " + $(if ($ok.stripe) { 'OK' } else { 'starting' })) -ForegroundColor $(if ($ok.stripe) { 'Green' } else { 'Yellow' })
}
if (-not $SkipNlp) {
    Write-Host ("  NLP API (opt.)   :5002  " + $(if ($ok.nlp) { 'OK' } else { 'starting / optional' })) -ForegroundColor $(if ($ok.nlp) { 'Green' } else { 'DarkGray' })
}
Write-Host ''
Write-Host 'Keep all PowerShell backend windows OPEN.' -ForegroundColor DarkGray
Write-Host ''

if ($BackendsOnly) {
    Write-Host 'Backends only (-BackendsOnly). Start app: .\RUN-EDGE-FULL.ps1' -ForegroundColor Yellow
    exit 0
}

Write-Host 'User flow on Edge:' -ForegroundColor Cyan
Write-Host '  1 Home / 3D products (R2 CDN)'
Write-Host '  2 Live measurement -> Size prediction (:5001)'
Write-Host '  3 2D Try On tab — upload photo, pick kurta (:8765)'
Write-Host '  4 Find tailor — AI bot + Firebase tailor chat'
Write-Host '  5 Pay — Stripe (:8000)'
Write-Host ''

if ($FixFlutter) {
    & "$AppRoot\RUN-FIX-FLUTTER.ps1"
}

$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
# Fewer parallel Dart workers — helps Windows "DartWorker: 22" thread errors
$env:FLUTTER_WEB_AUTO_DETECT = 'false'
Set-Location $AppRoot

if ((Get-Process -Name 'dart' -ErrorAction SilentlyContinue | Measure-Object).Count -gt 4) {
    Write-Host 'Many dart.exe running — run .\RUN-FIX-FLUTTER.ps1 or close old Flutter terminals' -ForegroundColor Yellow
}

$defines = @(
    '--dart-define=SIZE_API_LOCAL=true',
    '--dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001',
    '--dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003',
    '--dart-define=TRYON_API_BASE=http://127.0.0.1:8765',
    '--dart-define=TRYON_APP_BASE=http://127.0.0.1:65106',
    '--dart-define=CLOTH_STUDIO_URL=$Shop/',
    "--dart-define=MEDIA_CDN_BASE=$R2/",
    '--dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000'
)
if (-not $SkipNlp) {
    $defines += '--dart-define=SMARTFITAO_CHAT_URL=http://127.0.0.1:5002/'
}

Invoke-FlutterWebSafe -Label 'SmartFitao User App' -Port 65106 -OpenBrowser -FlutterArgs $defines -ForceRestart:$ForceAppRestart
