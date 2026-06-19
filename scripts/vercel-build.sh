#!/usr/bin/env bash
set -euo pipefail

echo "=== SmartFitao Flutter Web — Vercel build ==="

export FLUTTER_HOME="/vercel/flutter"
if [ ! -d "$FLUTTER_HOME/.git" ]; then
  echo "Installing Flutter stable..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get

RENDER_API="https://fyp-backend-hi10.onrender.com"
SHOP_URL="https://fyp-web-code-deployment-flea.vercel.app"
TRYON_API="https://threed-studio-deploymentt.onrender.com"
MEDIA_CDN="https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev"
STRIPE_API="https://smartfitao-stripe-api.onrender.com"
CV_CAMERA="https://qr-code-scan-computer-visionj-git-main-nauman-irshads-projects.vercel.app"

flutter build web --release \
  --no-wasm-dry-run \
  --dart-define=CLOTH_PREDICT_BASE="$RENDER_API" \
  --dart-define=CLOTH_STUDIO_URL="${SHOP_URL}/" \
  --dart-define=TRYON_API_BASE="$TRYON_API" \
  --dart-define=MEDIA_CDN_BASE="${MEDIA_CDN}/" \
  --dart-define=STRIPE_PAYMENT_BASE="$STRIPE_API" \
  --dart-define=CV_CAMERA_BASE="$CV_CAMERA" \
  --dart-define=SIZE_API_LOCAL=false

echo "=== Build complete ==="
du -sh build/web
