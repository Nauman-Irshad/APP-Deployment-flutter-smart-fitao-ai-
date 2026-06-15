# Vercel CDN media (3D + reels)

**This folder is pushed to GitHub** and synced into the shop site for Vercel hosting.

The Flutter **APK does not include** these files. Phones download them over Wi‑Fi from:

`https://fyp-web-code-deployment-flea.vercel.app/`

## Contents

| Path | Purpose |
|------|---------|
| `landing page product/kurta/*.glb` | 3D kurta models |
| `landing page product/shalwar kameez/*.glb` | 3D shalwar models |
| `landing page product/fabric/*.webp` | Fabric thumbnails |
| `reels_videos/*.mp4` | Tailor reels |
| `app-models-catalog.json` | API list for Flutter app |

## Sync to website before Vercel deploy

```powershell
cd "E:\fyp whole backend\scripts"
.\sync_cdn_to_figma_public.ps1
```

Then commit + push this repo and redeploy Vercel.

## Regenerate catalog JSON

```powershell
cd "E:\fyp whole backend\App\scripts"
.\generate_app_models_catalog.ps1
```

(Source reads from this `vercel-cdn-media` folder.)
