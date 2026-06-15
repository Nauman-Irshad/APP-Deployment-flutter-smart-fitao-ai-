# Smart Fiatio 2D try-on API (same as id-2d-try-on npm run api, port 8765)
$root = Join-Path $PSScriptRoot "..\..\id-2d-try-on"
if (-not (Test-Path $root)) {
  Write-Error "id-2d-try-on not found at $root"
  exit 1
}
Set-Location $root
Write-Host "Starting 2D try-on API on http://127.0.0.1:8765 ..."
npm run api
