# Seller dashboard only (login, products upload, order tracking)
# Full stack: .\RUN-ALL-BACKEND-SERVICES.ps1 -WithAllApps  (includes 5190 + Stripe + APIs)
# Or only 3D server: scripts\start-local-product-server.ps1 (port 5190)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Write-Host "Launching Seller Dashboard on Edge..." -ForegroundColor Green
Write-Host "3D GLB upload needs: scripts\start-local-product-server.ps1 (port 5190)" -ForegroundColor Yellow
flutter run -t lib/main_seller_dashboard.dart -d edge
