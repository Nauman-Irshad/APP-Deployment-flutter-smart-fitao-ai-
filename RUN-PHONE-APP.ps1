# Phone / emulator — PC runs all Flask APIs; app uses your PC Wi‑Fi IP (not 127.0.0.1)
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-PHONE-APP.ps1              # backends + print flutter command
#   .\RUN-PHONE-APP.ps1 -RunOnPhone  # backends + flutter install on USB phone
#   .\RUN-PHONE-APP.ps1 -PcIp 192.168.1.5
#
# Requirements:
#   - Phone and PC on SAME Wi‑Fi
#   - USB debugging ON (if -RunOnPhone)
#   - Windows Firewall: allow inbound on ports below (or turn off for testing)

param(
    [string]$PcIp = '',
    [switch]$RunOnPhone,
    [switch]$SkipStripe,
    [switch]$WithLocalChat,
    [switch]$BackendsOnly
)

$ErrorActionPreference = 'Stop'
$AppRoot = $PSScriptRoot

function Get-LanIPv4 {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -match '^192\.168\.\d+\.\d+$' -or
            $_.IPAddress -match '^10\.\d+\.\d+\.\d+$'
        } |
        Sort-Object -Property InterfaceMetric |
        Select-Object -First 1 -ExpandProperty IPAddress
    if ($ip) { return $ip }
    return '127.0.0.1'
}

if ([string]::IsNullOrWhiteSpace($PcIp)) {
    $PcIp = Get-LanIPv4
}

Write-Host ""
Write-Host "=== SmartFitao — phone uses PC at $PcIp ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "On PC (keep windows open):" -ForegroundColor Yellow
Write-Host "  Size Flask      $PcIp :5001"
Write-Host "  CV camera       $PcIp :5003"
Write-Host "  2D try-on API   $PcIp :8765"
Write-Host "  3D upload       $PcIp :5190"
if (-not $SkipStripe) { Write-Host "  Stripe          $PcIp :8000" }
if ($WithLocalChat) { Write-Host "  Chat website    $PcIp :5177  (optional -WithLocalChat)" }
Write-Host ""
Write-Host "From PHONE browser test:" -ForegroundColor DarkGray
Write-Host "  http://${PcIp}:5001/"
Write-Host "  http://${PcIp}:5003/"
Write-Host ""

& "$AppRoot\RUN-ALL-BACKEND-SERVICES.ps1" @(
    if ($SkipStripe) { '-SkipStripe' }
)

if ($WithLocalChat) {
    $webScript = Join-Path $AppRoot 'scripts\start-local-website-for-app.ps1'
    if (Test-Path $webScript) {
        $webCmd = "& '$($webScript -replace "'", "''")'"
        Start-Process powershell -ArgumentList @(
            '-NoExit', '-Command',
            "`$Host.UI.RawUI.WindowTitle = 'Chat+GLB :5177'; $webCmd"
        ) | Out-Null
        Write-Host "  Started: Chat website :5177 (+ STUDIO_LOCAL_DEV + LOCAL_DEV_HOST on phone)" -ForegroundColor Green
    }
}

$defines = @(
    "--dart-define=LOCAL_DEV_HOST=$PcIp",
    "--dart-define=CLOTH_PREDICT_BASE=http://${PcIp}:5001",
    "--dart-define=CV_CAMERA_BASE=http://${PcIp}:5003",
    "--dart-define=TRYON_API_BASE=http://${PcIp}:8765",
    "--dart-define=LOCAL_PRODUCT_API_BASE=http://${PcIp}:5190",
    "--dart-define=CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/"
)
if ($WithLocalChat) {
    $defines += @(
        "--dart-define=STUDIO_LOCAL_DEV=true",
        "--dart-define=FORCE_REMOTE_CHAT=true"
    )
}
if (-not $SkipStripe) {
    $defines += "--dart-define=STRIPE_PAYMENT_BASE=http://${PcIp}:8000"
}

$flutterCmd = "flutter run -d android $($defines -join ' ')"

Write-Host ""
Write-Host "=== Flutter on phone (USB) ===" -ForegroundColor Green
Write-Host $flutterCmd -ForegroundColor White
Write-Host ""
Write-Host "Chat on phone: built-in NLP in APK (internet for 3D). Add -WithLocalChat for PC Vite chat." -ForegroundColor DarkGray
Write-Host "Firewall: allow inbound TCP 5001,5003,8765,5190,8000 on Private network (Windows Defender)." -ForegroundColor DarkGray
Write-Host "Test from phone Chrome: http://${PcIp}:5001/ and http://${PcIp}:5003/" -ForegroundColor DarkGray
Write-Host ""

if ($RunOnPhone -and -not $BackendsOnly) {
    $env:CI = 'true'
    Set-Location $AppRoot
    Invoke-Expression $flutterCmd
}
