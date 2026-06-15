# 3D models on Vercel (not in APK)

## How it works

| Layer | Role |
|--------|------|
| **APK** | UI only + small images (~few MB). No `.glb` files inside. |
| **Vercel** | Hosts GLB/GLTF + `app-models-catalog.json` (HTTPS CDN). |
| **Phone (Wi‑Fi / data)** | App calls API → gets URLs → `ModelViewer` streams the file. |

Default CDN: `https://fyp-web-code-deployment-flea.vercel.app`

Override at build time:

```powershell
flutter build apk --release --dart-define=STUDIO_API_BASE=https://your-shop.vercel.app
```

## API files (on Vercel `public/`)

1. **`/app-models-catalog.json`** — list of products with full `modelUrl` (best for the app).
2. **`/landing page product/manifest.json`** — fallback catalog (website format).
3. **`/landing page product/kurta/*.glb`** — actual 3D files.

Flutter code: `lib/User 3D Market Place/landing_models_api.dart`

## One-time: upload models to Vercel

From repo root:

```powershell
cd "E:\fyp whole backend\App\scripts"
.\generate_app_models_catalog.ps1
```

Then commit and push the **website** project (`Figma Design for Frontend/public/`) and redeploy Vercel.

Source GLBs live in: `App/landing page product/`

## Requirements on phone

- **Internet** (Wi‑Fi or mobile data) for 3D product cards.
- First open may take a few seconds while GLB downloads (cached by the WebView).

## APK size

Build slim APK:

```powershell
cd App
flutter build apk --release --split-per-abi
```

Use `app-arm64-v8a-release.apk` on most modern phones.
