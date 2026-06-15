# Builds app-models-catalog.json from App/landing page product/.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$srcDir = Join-Path $repoRoot "App\landing page product"
$out = Join-Path $repoRoot "App\assets\app-models-catalog.json"

if (-not (Test-Path $srcDir)) {
    Write-Error "Missing: $srcDir"
    exit 1
}

$models = @()
Get-ChildItem -Path $srcDir -Recurse -Filter *.glb | ForEach-Object {
    $rel = $_.FullName.Substring($srcDir.Length + 1) -replace '\\', '/'
    $models += @{
        name = $_.Name
        path = "landing page product/$rel"
    }
}

$catalog = @{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    baseUrl = '/landing page product'
    models = $models
}

$dir = Split-Path $out -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$catalog | ConvertTo-Json -Depth 6 | Set-Content -Path $out -Encoding UTF8
Write-Host "Wrote $out ($($models.Count) models)"
