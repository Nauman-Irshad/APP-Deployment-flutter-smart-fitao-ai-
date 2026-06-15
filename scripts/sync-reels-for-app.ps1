# Copy lib/User 3D Market Place/reels_videos -> web/reels_videos (Edge / flutter web).
$ErrorActionPreference = "Stop"
$app = Split-Path $PSScriptRoot -Parent
$src = Join-Path $app "lib\User 3D Market Place\reels_videos"
$dest = Join-Path $app "web\reels_videos"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Get-ChildItem $src -Filter "*.mp4" | Where-Object { $_.Length -gt 500000 } | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $dest $_.Name) -Force
  Write-Host "[sync-reels] $($_.Name) -> web/reels_videos/"
}
Write-Host "[sync-reels] Done. Phone uses lib/ via pubspec; Edge uses web/reels_videos/"
