# Sync landing media to App/web/ for flutter run (Edge/Chrome).
& (Join-Path $PSScriptRoot 'uncompress_landing_glbs.ps1')

$app = Split-Path $PSScriptRoot -Parent
$src = Join-Path $app 'landing page product'
$reelsSrc = Join-Path $app 'lib\User 3D Market Place\reels_videos'
$reelsWeb = Join-Path $app 'web\reels_videos'

New-Item -ItemType Directory -Path $reelsWeb -Force | Out-Null
Copy-Item -Path (Join-Path $src 'fabric\*') -Destination (Join-Path $app 'web\landing page product\fabric') -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $src 'kurta pajama .png') -Destination (Join-Path $app 'web\landing page product\') -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $src 'shalwar kameez (1).png') -Destination (Join-Path $app 'web\landing page product\') -Force -ErrorAction SilentlyContinue

Copy-Item -Path (Join-Path $reelsSrc 'tailor1.mp4') -Destination $reelsWeb -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $reelsSrc 'tailor2.mp4') -Destination $reelsWeb -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $reelsSrc '6767035-uhd_2160_3840_25fps.mp4') -Destination $reelsWeb -Force -ErrorAction SilentlyContinue
Write-Host 'Web sync complete (GLBs + fabric images + reels).'
