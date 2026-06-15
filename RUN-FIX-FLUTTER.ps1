# Fix DartWorker / "compiler exited unexpectedly" on Windows
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '=== Flutter repair (Windows) ===' -ForegroundColor Cyan
& "$PSScriptRoot\scripts\Stop-FlutterWorkers.ps1"

Write-Host 'flutter clean...' -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host ''
Write-Host 'OK. Now run ONLY one Flutter command:' -ForegroundColor Green
Write-Host '  .\RUN-EDGE-FULL.ps1' -ForegroundColor Cyan
Write-Host 'or (if backends already up):' -ForegroundColor DarkGray
Write-Host '  .\RUN-EDGE-MARKETPLACE.ps1' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Tip: close extra PowerShell backend windows if PC feels slow.' -ForegroundColor DarkGray
