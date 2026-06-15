# Serves 3D uploads on http://127.0.0.1:5190 (GLB zip upload + static /local-products/...)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script = Join-Path $root "website +dashboard front deployed\scripts\local-product-server.cjs"
if (-not (Test-Path $script)) {
  Write-Error "Not found: $script"
  exit 1
}
Write-Host "Starting local 3D product server on http://127.0.0.1:5190 ..."
Set-Location (Split-Path $script)
node $script
