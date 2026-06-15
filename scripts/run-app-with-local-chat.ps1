# Terminal 1: run start-local-website-for-app.ps1
# This script only prints the Flutter command for Terminal 2.
$host.UI.RawUI.WindowTitle = "SmartFitao - Flutter (local NLP chat)"
Write-Host @"

=== Local NLP chat ===
1) In another PowerShell, run:
   .\scripts\start-local-website-for-app.ps1

2) Wait until you see:  Local: http://127.0.0.1:5177/

3) Then run Flutter (from App folder):

   flutter run -d edge --dart-define=STUDIO_LOCAL_DEV=true

   Android emulator:
   flutter run -d android --dart-define=STUDIO_LOCAL_DEV=true

   Phone on Wi-Fi (replace with your PC IP):
   flutter run -d android --dart-define=STUDIO_LOCAL_DEV=true --dart-define=LOCAL_DEV_HOST=192.168.1.5

"@
