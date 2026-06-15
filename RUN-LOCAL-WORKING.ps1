# Local SmartFitao on Edge — size :5001 | camera :5003 | 2D :8765 | AI chat :5002
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-LOCAL-WORKING.ps1
#
# Starts missing backends only, then Flutter on http://127.0.0.1:65106
# Plain `flutter run -d edge --web-port=65106` also uses local APIs on 127.0.0.1 (hot restart after code changes).

param(
    [switch]$BackendsOnly,
    [switch]$SkipNlp,
    [switch]$ForceRestart
)

$edgeParams = @{}
if ($BackendsOnly) { $edgeParams['BackendsOnly'] = $true }
if ($SkipNlp) { $edgeParams['SkipNlp'] = $true }
if ($ForceRestart) { $edgeParams['ForceAppRestart'] = $true }
& "$PSScriptRoot\RUN-EDGE-FULL.ps1" @edgeParams
