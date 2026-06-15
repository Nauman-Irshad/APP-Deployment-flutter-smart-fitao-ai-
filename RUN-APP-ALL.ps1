# ONE COMMAND — size prediction + CV + 2D try-on + Stripe + NLP + Flutter on Edge
#   cd "E:\fyp whole backend\App"
#   .\RUN-APP-ALL.ps1
#
# Same as RUN-EDGE-FULL.ps1 with a fresh Flutter dev server (local dart-defines).

param(
    [switch]$BackendsOnly,
    [switch]$SkipNlp,
    [switch]$SkipStripe
)

& "$PSScriptRoot\RUN-EDGE-FULL.ps1" @PSBoundParameters -ForceAppRestart -FixFlutter
