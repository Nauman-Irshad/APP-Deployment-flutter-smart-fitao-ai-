# Full user app: all backends (separate windows) + Flutter on Edge
#
#   cd "E:\fyp whole backend\App"
#   .\RUN-USER-APP.ps1

$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

& "$PSScriptRoot\RUN-ALL-BACKEND-SERVICES.ps1" -WithFlutter
