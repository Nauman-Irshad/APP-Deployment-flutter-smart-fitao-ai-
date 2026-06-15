# Customer + tailor chat test (two Edge windows)
$ErrorActionPreference = "Stop"
$AppRoot = $PSScriptRoot

Write-Host ""
Write-Host "=== Tailor chat test (2 windows) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "WINDOW 1 — Customer (marketplace + 2D try-on)" -ForegroundColor Green
Write-Host "  cd `"$AppRoot`""
Write-Host "  flutter run -d edge"
Write-Host ""
Write-Host "WINDOW 2 — Tailor (Messages inbox)" -ForegroundColor Green
Write-Host "  cd `"$AppRoot`""
Write-Host "  flutter run -d edge --web-port=65110"
Write-Host ""
Write-Host "Steps:" -ForegroundColor Yellow
Write-Host "  1. Customer: open Black kurta -> Live measurement -> Save size"
Write-Host "  2. Customer: bottom nav -> 2D Try On -> Find tailor -> pick YOUR Firebase tailor (not demo)"
Write-Host "  3. Customer: Chat -> + -> Product + Size chart + type a message"
Write-Host "  4. Tailor window: Login as tailor (real email/password) -> Messages tab"
Write-Host ""
Write-Host "Tailor must have users/{uid} with role=tailor and stitchingRate > 0" -ForegroundColor DarkGray
Write-Host ""

$startTailor = Read-Host "Open tailor window now? (y/n)"
if ($startTailor -eq 'y') {
    Start-Process powershell -ArgumentList @(
        "-NoExit", "-Command",
        "Set-Location '$AppRoot'; flutter run -d edge --web-port=65110"
    ) | Out-Null
    Write-Host "Tailor window starting on http://127.0.0.1:65110" -ForegroundColor Cyan
}

Set-Location $AppRoot
Write-Host "Starting customer app..." -ForegroundColor Green
flutter run -d edge
