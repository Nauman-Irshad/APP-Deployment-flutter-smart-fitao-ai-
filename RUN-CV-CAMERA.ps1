# Body-scan / camera CV for Flutter embed (port 5003)
# Example: http://127.0.0.1:5003/?flutter_embed=1&app_mode=1&auto_start=1
$ErrorActionPreference = "Stop"
$CvDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Computer Vision (Camera Work)"
if (-not (Test-Path (Join-Path $CvDir "app.py"))) {
    Write-Error "Not found: $CvDir\app.py"
}
Set-Location $CvDir
$env:SMARTFITAO_HTTP = '1'
$env:CAMERA_APP_PORT = '5003'
Write-Host "CV camera: http://127.0.0.1:5003" -ForegroundColor Green
Write-Host "Keep this window open while using Live Measurement / camera in the app." -ForegroundColor DarkGray
python app.py
