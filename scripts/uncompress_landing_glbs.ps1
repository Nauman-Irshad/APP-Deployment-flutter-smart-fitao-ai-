# Replace compressed GLBs with Edge-compatible uncompressed copies.
$ErrorActionPreference = 'Stop'
$app = Split-Path $PSScriptRoot -Parent
$landing = Join-Path $app 'landing page product'
$webLanding = Join-Path $app 'web\landing page product'
$repo = Split-Path $app -Parent

$chatbot = Join-Path $repo 'website +dashboard front deployed\Figma Design for Frontend\public\chatbot\3d\models'
$pifuhd = Join-Path $repo 'pifuhd-main\3d studio\virtual-tryon-platform\frontend\public\landing page product'

$map = @(
  @{ rel = 'kurta\black kurta .glb'; src = Join-Path $chatbot 'kurta\black kurta .glb' },
  @{ rel = 'kurta\brown kurta.glb'; src = Join-Path $chatbot 'kurta\brown kurta.glb' },
  @{ rel = 'kurta\sky blue kurta.glb'; src = Join-Path $chatbot 'kurta\sky blue kurta.glb' },
  @{ rel = 'kurta\WHITE.glb'; src = Join-Path $pifuhd 'kurta\WHITE.glb' },
  @{ rel = 'shalwar kameez\black shalwar kameez.glb'; src = Join-Path $chatbot 'shalwar kameez\black shalwar kameez.glb' },
  @{ rel = 'shalwar kameez\brown 1.glb'; src = Join-Path $chatbot 'shalwar kameez\brown 1.glb' },
  @{ rel = 'shalwar kameez\white shalwar kameez.glb'; src = Join-Path $chatbot 'shalwar kameez\white shalwar kameez.glb' },
  @{ rel = 'shalwar kameez\navy kurta 3d model.glb'; src = Join-Path $pifuhd 'shalwar kameez\navy kurta 3d model.glb' }
)

New-Item -ItemType Directory -Path $webLanding -Force | Out-Null

foreach ($item in $map) {
  if (-not (Test-Path $item.src)) {
    Write-Warning "Skip (missing source): $($item.rel)"
    continue
  }
  $destLanding = Join-Path $landing $item.rel
  $destWeb = Join-Path $webLanding $item.rel
  $dir = Split-Path $destLanding -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Copy-Item -LiteralPath $item.src -Destination $destLanding -Force
  $dirWeb = Split-Path $destWeb -Parent
  if (-not (Test-Path $dirWeb)) { New-Item -ItemType Directory -Path $dirWeb -Force | Out-Null }
  Copy-Item -LiteralPath $item.src -Destination $destWeb -Force
  $mb = [math]::Round((Get-Item $destLanding).Length / 1MB, 1)
  Write-Host "OK $($item.rel) ($mb MB)"
}

# Legacy single-file alias (optional)
$black = Join-Path $landing 'kurta\black kurta .glb'
if (Test-Path $black) {
  Copy-Item -LiteralPath $black -Destination (Join-Path $app 'web\black-kurta.glb') -Force
}

Write-Host "Done: uncompressed GLBs in landing page product + web/"
