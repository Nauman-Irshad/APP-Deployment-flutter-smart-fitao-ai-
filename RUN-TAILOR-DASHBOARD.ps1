# Tailor app - Messages, orders, income (demo: tailor.ahmed@smartfitao.pk / Tailor@12345)
# Full stack: .\RUN-ALL-BACKEND-SERVICES.ps1 -WithAllApps
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Write-Host "Tailor dashboard on http://127.0.0.1:65110" -ForegroundColor Green
Write-Host "Demo: tailor.ahmed@smartfitao.pk / Tailor@12345 - set stitching rate after login" -ForegroundColor Yellow
flutter run -t lib/main_tailor_dashboard.dart -d edge --web-port=65110
