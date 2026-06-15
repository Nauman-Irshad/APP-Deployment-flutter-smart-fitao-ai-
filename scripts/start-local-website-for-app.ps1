# Serves smart-fitao-chat + 3D GLBs for the Flutter app (Vite port 5177).
# Keep this window open while testing Messages -> AI Chat Bot locally.
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$candidates = @(
  (Join-Path $repoRoot "_gh_push\Figma Design for Frontend"),
  (Join-Path $repoRoot "website +dashboard front deployed\Figma Design for Frontend")
)
$figma = $candidates | Where-Object { Test-Path (Join-Path $_ "package.json") } | Select-Object -First 1
if (-not $figma) {
  Write-Error "Figma Design for Frontend not found. Clone fyp-web-code-deployment into _gh_push."
}
Set-Location $figma
if (-not (Test-Path "node_modules")) {
  Write-Host "[local-website] npm install..."
  npm install
}
Write-Host "[local-website] Starting Vite on 0.0.0.0:5177 (phone: http://YOUR_PC_IP:5177)"
Write-Host "[local-website] Chat: http://127.0.0.1:5177/smart-fitao-chat/?embed=1&mobile=1"
Write-Host "[local-website] Phone: flutter --dart-define=LOCAL_DEV_HOST=192.168.x.x --dart-define=STUDIO_LOCAL_DEV=true"
Write-Host ""
npm run dev
