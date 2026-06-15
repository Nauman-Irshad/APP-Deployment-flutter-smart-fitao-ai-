# Copy NLP chat (with 3D fix) into App assets + web/ for Edge & APK.
$ErrorActionPreference = "Stop"
$app = Split-Path $PSScriptRoot -Parent
$src = Join-Path (Split-Path $app -Parent) "_gh_push\Figma Design for Frontend\public\smart-fitao-chat"
if (-not (Test-Path $src)) { $src = Join-Path $app "assets\smart-fitao-chat" }
foreach ($dest in @(
  (Join-Path $app "assets\smart-fitao-chat"),
  (Join-Path $app "web\smart-fitao-chat")
)) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Copy-Item "$src\*" $dest -Recurse -Force
  Write-Host "[sync-chat] -> $dest"
}
# Ensure full GLB URLs for app bundle
$products = Join-Path $app "assets\smart-fitao-chat\data\products.json"
if (Test-Path $products) {
  $base = "https://fyp-web-code-deployment-flea.vercel.app"
  (Get-Content $products -Raw) -replace '"/chatbot/', "`"$base/chatbot/" | Set-Content $products -Encoding UTF8
}
Write-Host "[sync-chat] Done. Restart: flutter run -d edge"
