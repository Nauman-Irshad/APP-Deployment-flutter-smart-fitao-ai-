@echo off
cd /d "%~dp0"
echo Building SmartFitao release APK...
call flutter pub get
call flutter build apk --release --split-per-abi
if %ERRORLEVEL% NEQ 0 (
  echo Build failed.
  pause
  exit /b 1
)
echo.
echo APK files (pick arm64-v8a for most phones):
echo   build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo   build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo.
explorer "%CD%\build\app\outputs\flutter-apk"
pause
