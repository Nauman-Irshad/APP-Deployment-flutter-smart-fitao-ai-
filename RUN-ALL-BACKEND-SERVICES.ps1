# SmartFitao — one script for all local backends + optional Flutter apps
#
# Backends (each opens its own PowerShell window):
#   CV camera Flask       http://127.0.0.1:5003
#   NLP AI chatbot        http://127.0.0.1:5002
#   Size prediction       http://127.0.0.1:5001
#   2D try-on API         http://127.0.0.1:8765
#   Stripe checkout       http://127.0.0.1:8000
#   Seller 3D GLB upload  http://127.0.0.1:5190
#
# Flutter (optional):
#   User marketplace      http://127.0.0.1:65106  (-WithFlutter or -WithAllApps)
#   2D try-on flow        http://127.0.0.1:65109  (-WithAllApps)
#   Tailor dashboard      http://127.0.0.1:65110  (-WithAllApps)
#   Seller dashboard      http://127.0.0.1:65107  (-WithAllApps)
#
# Usage:
#   cd "E:\fyp whole backend\App"
#   .\RUN-ALL-BACKEND-SERVICES.ps1
#   .\RUN-ALL-BACKEND-SERVICES.ps1 -WithFlutter
#   .\RUN-ALL-BACKEND-SERVICES.ps1 -WithAllApps
#   .\RUN-ALL-BACKEND-SERVICES.ps1 -SkipStripe -WithFlutter

param(
    [switch]$WithFlutter,
    [switch]$WithAllApps,
    [switch]$SkipStripe,
    [switch]$Skip3DServer,
    [int]$UserPort = 65106,
    [int]$TryOnPort = 65109,
    [int]$TailorPort = 65110,
    [int]$SellerPort = 65107
)

$ErrorActionPreference = "Stop"
$AppRoot = $PSScriptRoot
$WsRoot = Split-Path $AppRoot -Parent

$SizeScript = Join-Path $WsRoot "pifuhd-main\Ai Cloth Size Prediction\start-flask.ps1"
$CvDir = Join-Path $WsRoot "Computer Vision (Camera Work)"
if (-not (Test-Path (Join-Path $CvDir "app.py"))) {
    $CvDir = Join-Path $AppRoot "lib\User 3D Market Place\camera_work_computer_vision\reference_original_server"
}
$TryOnRoot = Join-Path $WsRoot "id-2d-try-on"
$StripeRoot = Join-Path $WsRoot "strip payment gateway"
$NlpRoot = Join-Path $WsRoot "nlp chat bot"
$Local3DScript = Join-Path $AppRoot "scripts\start-local-product-server.ps1"

if (-not (Test-Path (Join-Path $TryOnRoot "package.json"))) {
    $alt = Join-Path $WsRoot "_backend_push\id-2d-try-on"
    if (Test-Path (Join-Path $alt "package.json")) { $TryOnRoot = $alt }
}

$FlutterDefines = @(
    "--dart-define=CV_CAMERA_BASE=http://127.0.0.1:5003",
    "--dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001",
    "--dart-define=TRYON_API_BASE=http://127.0.0.1:8765",
    "--dart-define=STRIPE_PAYMENT_BASE=http://127.0.0.1:8000",
    "--dart-define=LOCAL_PRODUCT_API_BASE=http://127.0.0.1:5190",
    "--dart-define=CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/"
)
$DefinesJoined = ($FlutterDefines | ForEach-Object { $_ }) -join ' '

function Start-ServiceWindow {
    param(
        [string]$Title,
        [string]$Command
    )
    $safeTitle = $Title -replace "'", "''"
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "`$Host.UI.RawUI.WindowTitle = '$safeTitle'; $Command"
    ) | Out-Null
    Write-Host "  Started: $Title" -ForegroundColor Green
}

function Test-HttpOk {
    param([string]$Url)
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return $r.StatusCode -ge 200 -and $r.StatusCode -lt 500
    } catch {
        return $false
    }
}

function Start-FlutterWindow {
    param(
        [string]$Title,
        [string]$Target,
        [int]$Port
    )
    $portArg = if ($Port -gt 0) { " --web-port=$Port" } else { "" }
    $cmd = @"
Set-Location '$($AppRoot -replace "'", "''")'
Write-Host '$Title on Edge$portArg' -ForegroundColor Green
flutter run -t $Target -d edge$portArg $DefinesJoined
"@
    Start-ServiceWindow $Title $cmd
}

Write-Host ""
Write-Host "=== SmartFitao - all backends (+ optional apps) ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SizeScript)) {
    Write-Error "Size API script not found: $SizeScript"
}
if (-not (Test-Path (Join-Path $CvDir "app.py"))) {
    Write-Error "CV app.py not found: $CvDir"
}
if (-not (Test-Path (Join-Path $TryOnRoot "package.json"))) {
    Write-Error "id-2d-try-on not found under $WsRoot"
}

$sizeCmd = "& '$($SizeScript -replace "'", "''")'"
Start-ServiceWindow "SmartFitao Size :5001" $sizeCmd

$cvCmd = @"
Set-Location '$($CvDir -replace "'", "''")'
`$env:SMARTFITAO_HTTP = '1'
`$env:CAMERA_APP_PORT = '5003'
python app.py
"@
Start-ServiceWindow "SmartFitao CV :5003" $cvCmd

$tryOnCmd = @"
Set-Location '$($TryOnRoot -replace "'", "''")'
Write-Host '2D try-on API on http://127.0.0.1:8765' -ForegroundColor Cyan
npm run api
"@
Start-ServiceWindow "SmartFitao 2D Try-On :8765" $tryOnCmd

if (-not $SkipStripe) {
    if (-not (Test-Path (Join-Path $StripeRoot "manage.py"))) {
        Write-Host "  [SKIP] Stripe - manage.py not found: $StripeRoot" -ForegroundColor Yellow
    } else {
        $stripeCmd = "& '$((Join-Path $StripeRoot 'RUN-STRIPE-SERVER.ps1') -replace "'", "''")'"
        Start-ServiceWindow "SmartFitao Stripe :8000" $stripeCmd
    }
} else {
    Write-Host "  [SKIP] Stripe (-SkipStripe)" -ForegroundColor DarkGray
}

if (-not $Skip3DServer) {
    if (-not (Test-Path $Local3DScript)) {
        Write-Host "  [SKIP] 3D server script missing: $Local3DScript" -ForegroundColor Yellow
    } else {
        $local3dCmd = "& '$($Local3DScript -replace "'", "''")'"
        Start-ServiceWindow "SmartFitao 3D Upload :5190" $local3dCmd
    }
} else {
    Write-Host "  [SKIP] 3D server (-Skip3DServer)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Waiting for services (size model may take 30-90s first time)..." -ForegroundColor Yellow
$deadline = (Get-Date).AddSeconds(90)
$sizeOk = $false
$cvOk = $false
$tryOk = $false
$stripeOk = $SkipStripe
$local3dOk = $Skip3DServer

while ((Get-Date) -lt $deadline) {
    if (-not $sizeOk) { $sizeOk = Test-HttpOk "http://127.0.0.1:5001/api/health" }
    if (-not $sizeOk) { $sizeOk = Test-HttpOk "http://127.0.0.1:5001/" }
    if (-not $cvOk) { $cvOk = Test-HttpOk "http://127.0.0.1:5003/" }
    if (-not $tryOk) { $tryOk = Test-HttpOk "http://127.0.0.1:8765/docs" }
    if (-not $tryOk) { $tryOk = Test-HttpOk "http://127.0.0.1:8765/" }
    if (-not $stripeOk) { $stripeOk = Test-HttpOk "http://127.0.0.1:8000/" }
    if (-not $local3dOk) { $local3dOk = Test-HttpOk "http://127.0.0.1:5190/api/local-products" }
    if ($sizeOk -and $cvOk -and $tryOk -and $stripeOk -and $local3dOk) { break }
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "Status:" -ForegroundColor Cyan
Write-Host ("  CV camera (5003):        " + $(if ($cvOk) { "OK" } else { "starting - check window" })) -ForegroundColor $(if ($cvOk) { "Green" } else { "Yellow" })
Write-Host ("  Size predict (5001):     " + $(if ($sizeOk) { "OK" } else { "starting - check window" })) -ForegroundColor $(if ($sizeOk) { "Green" } else { "Yellow" })
Write-Host ("  2D try-on API (8765):    " + $(if ($tryOk) { "OK" } else { "starting - check window" })) -ForegroundColor $(if ($tryOk) { "Green" } else { "Yellow" })
if (-not $SkipStripe) {
    Write-Host ("  Stripe payment (8000):   " + $(if ($stripeOk) { "OK" } else { "starting - check window" })) -ForegroundColor $(if ($stripeOk) { "Green" } else { "Yellow" })
}
if (-not $Skip3DServer) {
    Write-Host ("  3D GLB server (5190):    " + $(if ($local3dOk) { "OK" } else { "starting - check window" })) -ForegroundColor $(if ($local3dOk) { "Green" } else { "Yellow" })
}
Write-Host ""
Write-Host "Keep backend PowerShell windows open while testing." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Demo logins (see DEMO-ACCOUNTS.md):" -ForegroundColor Cyan
Write-Host "  User:   ali@smartfitao.pk"
Write-Host "  Tailor: tailor.ahmed@smartfitao.pk  (port $TailorPort)"
Write-Host "  Seller: seller.premium@smartfitao.pk"
Write-Host ""

if ($WithAllApps) {
    Write-Host "Starting all Flutter apps in separate windows..." -ForegroundColor Green
    Start-FlutterWindow "SmartFitao User :$UserPort" "lib/main.dart" $UserPort
    Start-Sleep -Seconds 2
    Start-FlutterWindow "SmartFitao 2D Try-On :$TryOnPort" "lib/main_2d_try_on.dart" $TryOnPort
    Start-Sleep -Seconds 2
    Start-FlutterWindow "SmartFitao Tailor :$TailorPort" "lib/main_tailor_dashboard.dart" $TailorPort
    Start-Sleep -Seconds 2
    Start-FlutterWindow "SmartFitao Seller :$SellerPort" "lib/main_seller_dashboard.dart" $SellerPort
    Write-Host ""
    Write-Host "URLs:" -ForegroundColor Cyan
    Write-Host "  User marketplace:  http://127.0.0.1:$UserPort"
    Write-Host "  2D try-on:         http://127.0.0.1:$TryOnPort"
    Write-Host "  Tailor dashboard:  http://127.0.0.1:$TailorPort"
    Write-Host "  Seller dashboard:  http://127.0.0.1:$SellerPort"
} elseif ($WithFlutter) {
    Set-Location $AppRoot
    Write-Host "Launching user marketplace on Edge (port $UserPort)..." -ForegroundColor Green
    flutter run -d edge --web-port=$UserPort @FlutterDefines
} else {
    Write-Host "Flutter (pick one):" -ForegroundColor Yellow
    Write-Host "  .\RUN-ALL-BACKEND-SERVICES.ps1 -WithFlutter     # user app only (this terminal)"
    Write-Host "  .\RUN-ALL-BACKEND-SERVICES.ps1 -WithAllApps     # user + try-on + tailor + seller"
    Write-Host ""
    Write-Host "Or run single dashboards (backends must stay up):" -ForegroundColor Yellow
    Write-Host "  .\RUN-SELLER-DASHBOARD.ps1"
    Write-Host "  .\RUN-TAILOR-DASHBOARD.ps1"
    Write-Host "  .\RUN-TRYON-65109.ps1"
    Write-Host "  .\RUN-EDGE-WITH-STRIPE.ps1"
}
