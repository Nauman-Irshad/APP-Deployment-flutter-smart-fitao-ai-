# Local backends for Edge: Size :5001, CV camera :5003, 2D try-on API :8765
# Then: .\RUN-EDGE-MARKETPLACE.ps1  (default local)

$ErrorActionPreference = 'Stop'
$AppRoot = $PSScriptRoot
$WsRoot = Split-Path $AppRoot -Parent
$SizeScript = Join-Path $WsRoot "pifuhd-main\Ai Cloth Size Prediction\start-flask.ps1"
$CvDir = Join-Path $WsRoot "Computer Vision (Camera Work)"
$TryOnRoot = Join-Path $WsRoot "id-2d-try-on"

if (-not (Test-Path $SizeScript)) { Write-Error "Not found: $SizeScript" }
if (-not (Test-Path (Join-Path $CvDir "app.py"))) { Write-Error "Not found: $CvDir\app.py" }
if (-not (Test-Path (Join-Path $TryOnRoot "package.json"))) { Write-Error "Not found: $TryOnRoot" }

function Test-PortUp([string]$Url) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 4
        return $r.StatusCode -lt 500
    } catch { return $false }
}

function Start-Win([string]$Title, [string]$Command) {
    $t = $Title -replace "'", "''"
    Start-Process powershell -ArgumentList @(
        '-NoExit', '-Command', "`$Host.UI.RawUI.WindowTitle = '$t'; $Command"
    ) | Out-Null
    Write-Host "  Started: $Title" -ForegroundColor Green
}

Write-Host 'Starting local backends...' -ForegroundColor Cyan

$sizeCmd = "& '$($SizeScript -replace "'", "''")'"
Start-Win 'SmartFitao Size :5001' $sizeCmd

$cvCmd = @"
Set-Location '$($CvDir -replace "'", "''")'
`$env:SMARTFITAO_HTTP = '1'
`$env:CAMERA_APP_PORT = '5003'
python app.py
"@
Start-Win 'SmartFitao CV :5003' $cvCmd

$tryCmd = @"
Set-Location '$($TryOnRoot -replace "'", "''")'
Write-Host 'Try-on API :8765 (real Hugging Face IDM-VTON — see .env TRYON_FAST)' -ForegroundColor Cyan
npm run api
"@
Start-Win 'SmartFitao 2D API :8765' $tryCmd

Write-Host 'Waiting for services...' -ForegroundColor Yellow
foreach ($i in 1..40) {
    $s = Test-PortUp 'http://127.0.0.1:5001/api/health'
    $c = Test-PortUp 'http://127.0.0.1:5003/'
    $t = Test-PortUp 'http://127.0.0.1:8765/docs'
    if (-not $t) { $t = Test-PortUp 'http://127.0.0.1:8765/' }
    if ($s -and $c -and $t) {
        Write-Host 'All local backends ready' -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 3
}

Write-Host '  Size :5001  CV :5003  2D API :8765' -ForegroundColor DarkGray
Write-Host 'Next (two terminals):' -ForegroundColor Cyan
Write-Host '  .\RUN-EDGE-MARKETPLACE.ps1   # shop :65106' -ForegroundColor Cyan
Write-Host '  .\RUN-2D-TRYON.ps1           # 2D app :65109 + API' -ForegroundColor Cyan
