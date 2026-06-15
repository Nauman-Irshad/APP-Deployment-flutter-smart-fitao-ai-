# Size predict (5001) + CV camera (5000) + reels sync + Flutter on Edge
$ErrorActionPreference = "Stop"
$appRoot = Split-Path $PSScriptRoot -Parent
$ws = Split-Path $appRoot -Parent

Write-Host "Syncing reels for Edge/web..."
& "$appRoot\scripts\sync-reels-for-app.ps1"

$sizeScript = Join-Path $ws "pifuhd-main\Ai Cloth Size Prediction\start-flask.ps1"
$cvDir = Join-Path $appRoot "lib\User 3D Market Place\camera_work_computer_vision\reference_original_server"

function Start-JobWindow($title, $command) {
    Start-Process powershell -ArgumentList @(
        "-NoExit", "-Command",
        "`$Host.UI.RawUI.WindowTitle = '$title'; $command"
    ) | Out-Null
}

Write-Host "Starting Flask size API (port 5001)..."
Start-JobWindow "SmartFitao Size :5001" "& '$sizeScript'"

Write-Host "Starting CV camera server (port 5000)..."
Start-JobWindow "SmartFitao CV :5000" @"
Set-Location '$cvDir'
`$env:SMARTFITAO_HTTP = '1'
python app.py
"@

Write-Host "Waiting for APIs..."
Start-Sleep -Seconds 8

Set-Location $appRoot
Write-Host "Launching Flutter on Edge..."
flutter run -d edge --web-port=65106 `
  --dart-define=CLOTH_PREDICT_BASE=http://127.0.0.1:5001 `
  --dart-define=CV_CAMERA_BASE=http://127.0.0.1:5000 `
  --dart-define=CLOTH_STUDIO_URL=https://fyp-web-code-deployment-flea.vercel.app/
