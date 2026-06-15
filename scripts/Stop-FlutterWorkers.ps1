# Fixes: "Could not start thread DartWorker" / Dart compiler exited unexpectedly (Windows)
# Run before flutter run if compile keeps crashing.

Write-Host 'Stopping stale Dart / Flutter processes...' -ForegroundColor Cyan
$names = @('dart', 'dartaotruntime', 'flutter_tester', 'chrome', 'msedge')
foreach ($n in $names) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
        # Keep user's normal Edge browser — only kill if many edge + high memory from flutter tool
        if ($n -eq 'msedge' -or $n -eq 'chrome') { return }
        Write-Host "  Stop $($_.ProcessName) pid $($_.Id)" -ForegroundColor DarkGray
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}
# Dart SDK workers (main culprit)
Get-Process -Name 'dart' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name 'dartaotruntime' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2
Write-Host 'Done. If Edge was closed, reopen http://127.0.0.1:65106 after flutter run.' -ForegroundColor Green
